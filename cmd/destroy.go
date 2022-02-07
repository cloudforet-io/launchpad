/*
Copyright © 2021 SpaceONE <spaceone-support@mz.co.kr>

*/
package cmd

import (
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

// destroyCmd represents the destroy command
var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy SpaceONE",
	Long:  `Destroy all results installed by launchpad.`,
	Run: func(cmd *cobra.Command, args []string) {
		_checkInstalledType()
		_setAwsCredentais()	
		_setKubectlConfig()

		Destroy()
	},
}

func init() {
	rootCmd.AddCommand(destroyCmd)
}

func Destroy() {
	log.Println("Destroy SpaceONE")

	components := []string{"initialization", "deployment", "secret", "documentdb", "controllers", "eks", "certificate"}

	for _, component := range components {
		terraformState := fmt.Sprintf("./data/tfstates/%s.tfstate", component)
		if _, err := os.Stat(terraformState); err == nil {
			_executeTerraform(component, "destroy")
		}
	}

	err := _removeHelmData()
	if err != nil {
		panic(err)
	}

	err = _removeTerraformData(&components)
	if err != nil {
		panic(err)
	}

	err = _removeGpgKeyBinary()
	if err != nil {
		panic(err)
	}

	err = _removeKubeConfig()
	if err != nil {
		panic(err)
	}

	log.Println("SpaceONE Destroy completed")

}

func _checkInstalledType() {
	if _, err := os.Stat("./data/helm/values/spaceone/minimal.yaml"); err == nil {
		os.Setenv("TF_VAR_minimal", "true")
	}

	if _, err := os.Stat("./data/helm/values/spaceone/internal_minimal.yaml"); err == nil {
		os.Setenv("TF_VAR_internal_minimal", "true")
	}
}

func _removeHelmData() error {
	initializerHelmValuePath := "./data/helm/values/spaceone-initializer/*"
	err := _deleteFiles(initializerHelmValuePath)
	if err != nil {
		return err
	}

	spaceoneHelmValuePath := "./data/helm/values/spaceone/*"
	err = _deleteFiles(spaceoneHelmValuePath)
	if err != nil {
		return err
	}
	
	helmRepositoryConfig := "./data/helm/config/*"
	err = _deleteFiles(helmRepositoryConfig)
	if err != nil {
		return err
	}
	
	helmRepositoryCache := "./data/helm/cache/repository/*"
	err = _deleteFiles(helmRepositoryCache)
	if err != nil {
		return err
	}
	
	return nil
}

func _removeTerraformData(components *[]string) error {
	for _, component := range *components {
		tfvar := fmt.Sprintf("./module/%s/%s.auto.tfvars", component, component)
		err := _deleteSinglefile(tfvar)
		if err != nil {
			return err
		}

		terraformState := fmt.Sprintf("./data/tfstates/%s.tfstate*", component)
		err = _deleteFiles(terraformState)
		if err != nil {
			return err
		}
	}

	return nil
}

func _removeGpgKeyBinary() error {
	publicKeyBinary := "./module/secret/gpg/public-key-binary.gpg"
	err := _deleteSinglefile(publicKeyBinary)
	if err != nil {
		return err
	}

	secretKey := "./module/secret/gpg/secret-key"
	err = _deleteSinglefile(secretKey)
	if err != nil {
		return err
	}

	return nil
}

func _removeKubeConfig() error {
	kubeConfig := "./data/kubeconfig/config"
	err := _deleteSinglefile(kubeConfig)
	if err != nil {
		return err
	}

	return nil
}
