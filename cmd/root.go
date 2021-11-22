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
	helmclient "github.com/mittwald/go-helm-client"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "launchpad",
	Short: "SpaceONE launchpad",
	Long:  `Install and Management SpaceONE in the standard configuration`,
	// Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}

func init() {
	cobra.OnInitialize(initConfig)
	// Here you will define your flags and configuration settings.
	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.launchpad.yaml)")
	// rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)

		// Search config in home directory with name ".launchpad" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigType("yaml")
		viper.SetConfigName(".launchpad")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}
}

func executeTerraform(component string, action string) {
	//https://github.com/briandowns/spinner#available-character-sets
	s := spinner.New(spinner.CharSets[26], 100*time.Millisecond)
	s.Prefix = fmt.Sprintf("[%v] %v", action, component)

	s.Start()

	err := _init(component)
	if err != nil {
		panic(err)
	}

	switch action {
	case "install":
		err = _plan(component)
		if err != nil {
			panic(err)
		}

		err = _apply(component)
		if err != nil {
			panic(err)
		}
	case "destroy":
		err = _destroy(component)
		if err != nil {
			panic(err)
		}
	}

	s.Stop()
}

func _setAwsCredentais() {
	homedir, _ := os.UserHomeDir()
	// TODO: filepath module vs text path
	os.Mkdir(filepath.Join(homedir, ".aws"), 0755)

	src := filepath.Join("./vars", "aws_credential")
	dst := filepath.Join(homedir, ".aws/credentials")
	err := _file_copy(src, dst)
	if err != nil {
		panic(err)
	}

	_setTfvarRegion(src)
}

func _setKubectlConfig() error {
	err := os.Setenv("KUBECONFIG", "/spaceone/data/kubeconfig/config")
	if err != nil {
		return errors.Wrap(err, "Error set kubectl config")
	}

	return nil
}

func _file_copy(src, dst string) error {
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

func _setTfvarRegion(file_source string) {
	file, err := os.Open(file_source)
	cobra.CheckErr(err)
	defer file.Close()

	//TODO : Refactoring to use the Go scanner
	cmd := fmt.Sprintf("grep region %v | cut -d'=' -f2 | tr -d ' '", file_source)
	output, err := exec.Command("bash", "-c", cmd).Output()
	cobra.CheckErr(err)

	region := strings.TrimSuffix(string(output), "\n")
	os.Setenv("TF_VAR_region", region)
}

func _setTerraform(component string) (*tfexec.Terraform, error) {
	workingDir := fmt.Sprintf("./module/%v", component)

	execPath, err := tfinstall.Find(context.Background(), tfinstall.LatestVersion("/usr/bin/", false))
	if err != nil {
		return nil, errors.Wrap(err, "Error locating Terraform binary")
	}

	tf, err := tfexec.NewTerraform(workingDir, string(execPath))
	if err != nil {
		return nil, errors.Wrap(err, "Error running NewTerraform")
	}

	return tf, nil
}

func _getHelmClient() helmclient.Client {

	repositoryCachePath := "./data/helm/cache/repository"
	repositoryConfigPath := "./data/helm/config/repositories.yaml"

	opt := &helmclient.Options{
		RepositoryCache:  repositoryCachePath,
		RepositoryConfig: repositoryConfigPath,
		Debug:            true,
		Linting:          true,
	}

	helmClient, err := helmclient.New(opt)
	if err != nil {
		panic(err)
	}

	return helmClient
}
