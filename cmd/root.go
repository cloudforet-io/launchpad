/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

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
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/briandowns/spinner"
	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/hashicorp/terraform-exec/tfinstall"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

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
	homedir, _ := os.UserHomeDir()
	// TODO: filepath module vs text path
	os.Mkdir(filepath.Join(homedir, ".aws"), 0755)

	src := filepath.Join("./vars", "aws_credential")
	dst := filepath.Join(homedir, ".aws/credentials")
	err := _fileCopy(src, dst)
	if err != nil {
		panic(err)
	}

	_setTfvarRegion(src)
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

func _setTfvarRegion(file_source string) {
	file, err := os.Open(file_source)
	cobra.CheckErr(err)
	defer file.Close()

	//TODO : Refactoring to use the Go scanner
	cmd := fmt.Sprintf("grep region %v | cut -d'=' -f2 | tr -d ' '", file_source)
	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(err)
	}

	region := strings.TrimSuffix(string(output), "\n")
	os.Setenv("TF_VAR_region", region)
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
	s.FinalMSG = "ok\n"

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
