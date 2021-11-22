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
	"os/exec"
	"time"

	"github.com/briandowns/spinner"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// upgradeCmd represents the upgrade command
var upgradeCmd = &cobra.Command{
	Use:   "upgrade",
	Short: "Upgrade SpaceONE helm release",
	Long:  `Long description`,
	Run: func(cmd *cobra.Command, args []string) {
		_setAwsCredentais()
		_setKubectlConfig()

		isRepoUpdate, err := cmd.Flags().GetBool("update-repo")
		cobra.CheckErr(err)

		if isRepoUpdate {
			_updateHelmRepo()
		}

		upgrade()
	},
}

func init() {
	rootCmd.AddCommand(upgradeCmd)

	upgradeCmd.Flags().BoolP("update-repo", "", false, "Update helm repo before upgrade helm chart")
}

func upgrade() {
	//https://pkg.go.dev/github.com/mittwald/go-helm-client#HelmClient.InstallOrUpgradeChart
	s := spinner.New(spinner.CharSets[26], 100*time.Millisecond)
	s.Prefix = "Upgrade SpaceONE"

	s.Start()
	_upgradeHelmRelease()
	s.Stop()

	log.Println("\nSpaceONE upgrade complete")
}

// TODO: Using go helm client
func _upgradeHelmRelease() {
	repositoryCachePath := "./data/helm/cache/repository"
	repositoryConfigPath := "./data/helm/config/repositories.yaml"

	helmValueFiles := _getHelmValues()

	args := []string{
		"upgrade",
		"spaceone",
		"spaceone/spaceone",
		"-n", "spaceone",
		"-f", (*helmValueFiles)[0],
		"-f", (*helmValueFiles)[1],
		"-f", (*helmValueFiles)[2],
		"--repository-cache", repositoryCachePath,
		"--repository-config", repositoryConfigPath,
	}

	cmd := exec.Command(
		"helm",
		args...,
	)

	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, string(stdoutStderr)))
	}
}

// TODO: Using go helm client
func _updateHelmRepo() {
	repositoryCachePath := "./data/helm/cache/repository"
	repositoryConfigPath := "./data/helm/config/repositories.yaml"

	args := []string{
		"repo",
		"update",
		"--repository-cache", repositoryCachePath,
		"--repository-config", repositoryConfigPath,
	}

	cmd := exec.Command("helm", args...)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, string(stdoutStderr)))
	}
}

func _getHelmValues() *[]string {
	var valueYamls []string
	var fileNames = []string{"values.yaml", "frontend.yaml", "database.yaml"}

	for _, fileName := range fileNames {
		path := fmt.Sprintf("./data/helm/values/spaceone/%s", fileName)

		valueYamls = append(valueYamls, path)
	}

	return &valueYamls
}
