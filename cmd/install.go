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
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// installCmd represents the install command
var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Install SpaceONE from eks to spaceone package",
	Long:  `Long description`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()

		isDevelop, err := cmd.Flags().GetBool("devel")
		cobra.CheckErr(err)

		components := _getInstallComponents(isDevelop)

		build(&components)
	},
}

func init() {
	rootCmd.AddCommand(installCmd)
	// Here you will define your flags and configuration settings.
	// installCmd.PersistentFlags().String("foo", "", "A help for foo")
	// installCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	installCmd.Flags().BoolP("devel", "", false, "install develop mode")
}

func build(components *[]string) {
	log.Println("Start building SpaceONE")

	for _, component := range *components {
		if component != "secret" && component != "controllers" {
			err := _generateTfvars(component)
			if err != nil {
				panic(err)
			}
		}
		if component == "secret" {
			if err := _generateGpgKey(); err != nil {
				panic(err)
			}
		}

		_executeTerraform(component, "install")
	}

	log.Println("\nSpaceONE build complete")
}

func _getInstallComponents(isDevelop bool) []string {
	if isDevelop {
		os.Setenv("TF_VAR_development", "ture")
		return []string{"certificate", "eks", "controllers", "deployment", "initialization"}
	} else {
		os.Setenv("TF_VAR_enterprise", "true")
		return []string{"certificate", "eks", "controllers", "documentdb", "secret", "deployment", "initialization"}
	}
}

//TODO: Using gpg client
func _generateGpgKey() error {
	gpgConfigPath := "/tmp/gpg_config"
	gpgConfig, err := os.Create(gpgConfigPath)
	if err != nil {
		return errors.Wrap(err, "Failed to Create gpg config file")
	}
	defer gpgConfig.Close()

	configurations := []byte(`%echo Generating a key type RSA
Key-Type: RSA
Subkey-Type: RSA
Name-Real: spaceone
Name-Comment: Encrypt AWS Secrets
Name-Email: gpg@spaceone.org
Expire-Date: 2
Passphrase: spaceone
%commit
%echo done`)
	_, err = io.WriteString(gpgConfig, string(configurations))
	if err != nil {
		return errors.Wrap(err, "Failed to Write gpg config to file")
	}

	err = exec.Command("gpg", "--no-tty", "--batch", "--gen-key", gpgConfigPath).Run()
	if err != nil {
		return errors.Wrap(err, "gpg key generation command error")
	}

	err = exec.Command("gpg", "--output", "./module/secret/gpg/public-key-binary.gpg", "--export", "gpg@spaceone.org").Run()
	if err != nil {
		return errors.Wrap(err, "Failed to export gpg key")
	}

	return nil
}

func _generateTfvars(component string) error {
	src := fmt.Sprintf("./vars/%v.conf", component)
	dst := fmt.Sprintf("./module/%v/%v.auto.tfvars", component, component)
	err := _file_copy(src, dst)
	if err != nil {
		return errors.Wrap(err, "Failed to generate tfvars")
	}

	return err
}
