/*
Copyright © 2021 SpaceONE <spaceone-support@mz.co.kr>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"context"
	"fmt"
	"io"
	"os"
	"time"
	"io/ioutil"

	"gopkg.in/yaml.v2"
	"github.com/briandowns/spinner"
	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/hashicorp/terraform-exec/tfinstall"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

type Credential struct {
    Aws map[string]string `yaml:"aws,omitempty"`
}

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "launchpad",
	Short: "SpaceONE launchpad",
	Long: `Install and Management SpaceONE

Set the variable before installing SpaceONE.`,
	// Run: func(cmd *cobra.Command, args []string) { },
}

// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}

func init() {
	cobra.OnInitialize(initConfig)
}

//Not used.
func initConfig() {
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)

		viper.AddConfigPath(home)
		viper.SetConfigType("yaml")
		viper.SetConfigName(".launchpad")
	}

	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}
}

func _setAwsCredentais() {
	buf, err := ioutil.ReadFile("./vars/aws_credential.yaml")
	if err != nil {
		panic(errors.Wrap(err, "Failed to read aws_credential.yaml"))
	}

	var credential Credential

	err = yaml.Unmarshal(buf, &credential)
	if err != nil {
		panic(errors.Wrap(err, "Failed to yaml unmarshal"))
	}

	access_key := credential.Aws["aws_access_key_id"]
	secret_key := credential.Aws["aws_secret_access_key"]
	regoin 	   := credential.Aws["region"]

	os.Setenv("AWS_ACCESS_KEY_ID", access_key)
	os.Setenv("AWS_SECRET_ACCESS_KEY", secret_key)
	os.Setenv("AWS_DEFAULT_REGION", regoin)
}

func _setKubectlConfig() error {
	err := os.Setenv("KUBECONFIG", "/spaceone/data/kubeconfig/config")
	if err != nil {
		return errors.Wrap(err, "Kubectl config environment set error")
	}

	return nil
}

func _fileCopy(src, dst string) error {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return err
	}

	if !sourceFileStat.Mode().IsRegular() {
		return errors.Wrap(err, "not a regular file")
	}

	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()

	_, err = io.Copy(destination, source)
	return err
}

func _checkContainFile(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}

	return false
}

/**
terraform client
**/

func _setTerraform(component string) (*tfexec.Terraform, error) {
	workingDir := fmt.Sprintf("./module/%v", component)
	terraformBinPath := "/usr/bin/"

	execPath, err := tfinstall.Find(context.Background(), tfinstall.LatestVersion(terraformBinPath, false))
	if err != nil {
		return nil, errors.Wrap(err, "Cannot find Terraform Binary")
	}

	tf, err := tfexec.NewTerraform(workingDir, string(execPath))
	if err != nil {
		return nil, errors.Wrap(err, "Failed to set NewTerraform")
	}

	return tf, nil
}

func _executeTerraform(component string, action string) {
	// refer:https://github.com/briandowns/spinner#available-character-sets
	s := spinner.New(spinner.CharSets[26], 100*time.Millisecond)
	s.Prefix = fmt.Sprintf("[%v] %v", action, component)
	s.FinalMSG = "done\n"

	s.Start()

	tf, err := _setTerraform(component)
	if err != nil {
		panic(err)
	}

	err = _init(tf, component)
	if err != nil {
		panic(err)
	}

	switch action {
	case "install":
		err = _plan(tf, component)
		if err != nil {
			panic(err)
		}

		err = _apply(tf, component)
		if err != nil {
			panic(err)
		}
	case "destroy":
		err = _destroy(tf, component)
		if err != nil {
			panic(err)
		}
	}

	s.Stop()
}

func _init(tf *tfexec.Terraform, component string) error {
	err := tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		return errors.Wrap(err, "Failed to terraform Init")
	}

	return nil
}

func _plan(tf *tfexec.Terraform, component string) error {
	_, err := tf.Plan(context.Background())
	if err != nil {
		return errors.Wrap(err, "Failed to terraform Plan")
	}

	return nil
}

func _apply(tf *tfexec.Terraform, component string) error {
	err := tf.Apply(context.Background())
	if err != nil {
		return errors.Wrap(err, "Failed to terraform Apply")
	}

	return nil
}

func _destroy(tf *tfexec.Terraform, component string) error {
	err := tf.Destroy(context.Background())
	if err != nil {
		return errors.Wrap(err, "Failed to Terraform Destroy")
	}

	return nil
}
