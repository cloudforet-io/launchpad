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
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// destroyCmd represents the destroy command
var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy SpaceONE from eks to spaceone package",
	Long:  `Long description`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()
		destroy()
	},
}

func init() {
	rootCmd.AddCommand(destroyCmd)
}

func destroy() {
	log.Println("Destroy SpaceONE")

	components := []string{"initialization", "deployment", "secret", "documentdb", "controllers", "eks", "certificate"}

	err := _uninstallHelmRelease()
	if err != nil {
		panic(err)
	}

	err = _deleteKubernetesNamespace()
	if err != nil {
		panic(err)
	}

	for _, component := range components {
		if component != "deployment" && component != "initialization" {
			_executeTerraform(component, "destroy")
		}
	}

	err = _removeConfigure(&components)
	if err != nil {
		panic(err)
	}

	log.Println("\nSpaceONE Destroy completed")

}

func _uninstallHelmRelease() error {
	err := _UninstallRelease("user-domain", "spaceone-initializer")
	if err != nil {
		return err
	}

	err = _UninstallRelease("spaceone", "spaceone")
	if err != nil {
		return err
	}

	// Waiting for k8s resources to be deleted
	time.Sleep(5 * time.Second)

	initializerHelmValues := "./data/helm/values/spaceone-initializer/*"
	if files, err := filepath.Glob(initializerHelmValues); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Error delete spaceone-initailzer helm release values")
			}
		}
	}

	spaceoneHelmValues := "./data/helm/values/spaceone/*"
	if files, err := filepath.Glob(spaceoneHelmValues); err == nil {
		for _, f := range files {
			if err := os.Remove(f); err != nil {
				return errors.Wrap(err, "Error delete spaceone helm release values")
			}
		}
	}

	return nil
}

func _deleteKubernetesNamespace() error {
	// TODO: use kubectl or kubernetes client
	err := exec.Command("kubectl", "delete", "ns", "root-supervisor").Run()
	if err != nil {
		return errors.Wrap(err, "Error Delete namespace root-supervisor")
	}

	err = exec.Command("kubectl", "delete", "ns", "spaceone").Run()
	if err != nil {
		return errors.Wrap(err, "Error Delete namespace spaceone")
	}

	return nil
}

func _removeConfigure(components *[]string) error {

	for _, component := range *components {
		tfvar := fmt.Sprintf("./module/%s/%s.auto.tfvars", component, component)
		if _, err := os.Stat(tfvar); !os.IsNotExist(err) {
			os.Remove(tfvar)
		}

		terraformState := fmt.Sprintf("./data/tfstates/%s.tfstate*", component)
		if files, err := filepath.Glob(terraformState); err == nil {
			for _, f := range files {
				if err := os.Remove(f); err != nil {
					return errors.Wrap(err, "Error delete terraform states")
				}
			}
		}
	}

	publicKeyBinary := "./module/secret/gpg/public-key-binary.gpg"
	if _, err := os.Stat(publicKeyBinary); !os.IsNotExist(err) {
		os.Remove(publicKeyBinary)
	}

	kubeConfig := "./data/kubeconfig/config"
	if _, err := os.Stat(kubeConfig); !os.IsNotExist(err) {
		os.Remove(kubeConfig)
	}

	return nil
}
