/*
Copyright © 2021 SpaceONE <spaceone-support@mz.co.kr>

*/
package cmd

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

// deployCmd represents the deploy command
var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy SpaceONE",
	Long: `Deploy SpaceONE micro-services excluding infrastructure resources`,
	Run: func(cmd *cobra.Command, args []string) {
		_setKubectlConfig()

		isMinimal, _ := cmd.Flags().GetBool("minimal")
		deploy(isMinimal)
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)
	deployCmd.Flags().Bool("minimal", true, "install minimal mode")
}

func deploy(isMinimal bool) {
	log.Println("Start SpaceONE Micro-services deployment")

	components := _getDeployComponents(isMinimal)

	for _, component := range components {
		err := _generateTfvars(component)
		if err != nil {
			panic(err)
		}

		for _, component := range components {
			_executeTerraform(component, "install")
		}
	
		if isMinimal {
			_setDomainWhereNoIngress()
		}
	}
}

func _setDomainWhereNoIngress() {
	log.Println("_setDomainWhereNoIngress")

	nodeIp := _getNodeIp()
	consoleNodePort := _getNodePort("console")
	consoleApiNodePort := _getNodePort("console-api")

	cmd := fmt.Sprintf("sed -i 's/console-api.example.com/%s:%s/' ./data/helm/values/spaceone/minimal.yaml", nodeIp,consoleApiNodePort)
	_, err := exec.Command("bash", "-c", cmd).CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, "Failed to Update console-api domain"))
	}

	// cmd = fmt.Sprintf("sed -i 's/monitoring-webhook.example.com/%s/' ./data/helm/values/spaceone/minimal.yaml", monitoringWebhookDomainName)
	// _, err = exec.Command("bash", "-c", cmd).CombinedOutput()
	// if err != nil {
	// 	panic(errors.Wrap(err, "Failed to Update monitoring-webhook domain"))
	// }

	// Update configmap
	upgrade()

	// To mount the updated configmap to console pod
	_restartConsolePod()
	
	hostSetMsg := "\n" +
	"****************************************************************************************\n" +
	"\n"+
	fmt.Sprintf("Console endpoint http://%s:%s", nodeIp, consoleNodePort) +
	"\n"+
	"****************************************************************************************"
	log.Println(hostSetMsg)
}

func _getNodeIp() string {
	cmd := "kubectl get nodes `k get nodes | grep -v NAME | awk '{print $1}' | head -1` --output=custom-columns='IP:.status.addresses[0].address' | tail -1"

	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(errors.Wrap(err, "Failed to get node ip"))
	}

	nodeIp := strings.TrimSuffix(string(output), "\n")

	return nodeIp
}

func _getNodePort(ServiceName string) string {
	cmd := fmt.Sprintf("k get svc %s -n spaceone --output=custom-columns='nodePort:.spec.ports[0].nodePort' | tail -1", ServiceName)

	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(errors.Wrap(err, "Failed to get node ip"))
	}

	NodePort := strings.TrimSuffix(string(output), "\n")

	return NodePort

}

func _getDeployComponents(isMinimal bool) []string {
	if isMinimal { 
		os.Setenv("TF_VAR_internal_minimal", "true")
		return []string{"deployment", "initialization"}
	} else {
		os.Setenv("TF_VAR_internal_minimal", "true")
		return []string{"deployment", "initialization"}
	}
}


