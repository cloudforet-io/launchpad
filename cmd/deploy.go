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
	Long: `Deploy SpaceONE micro-services`,
	Run: func(cmd *cobra.Command, args []string) {
		_setKubectlConfig()

		Deploy()
		
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)
	//deployCmd.Flags().Bool("minimal", false, "install minimal mode")
}

func Deploy() {
	log.Println("Start SpaceONE Micro-services deployment")

	components := _getDeployComponents()

	for _, component := range components {
		err := _generateTfvars(component)
		if err != nil {
			panic(err)
		}

		_executeTerraform(component, "install")
	}

	_setDomainForInternal()
	
	log.Println("SpaceONE Deployment complete")
}

func _getDeployComponents() []string {
	os.Setenv("TF_VAR_internal", "true")
	return []string{"deployment", "initialization"}
}

func _setDomainForInternal() {
	nodeIp := _getNodeIp()
	consoleNodePort := _getNodePort("console")
	consoleApiNodePort := _getNodePort("console-api")

	cmd := fmt.Sprintf("sed -i 's/console-api.example.com/%v:%v/' ./data/helm/values/spaceone/frontend.yaml", nodeIp,consoleApiNodePort)
	_, err := exec.Command("bash", "-c", cmd).CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, "Failed to Update console-api domain"))
	}

	cmd = fmt.Sprintf("sed -i 's/domain_reference/%v/' ./data/helm/values/spaceone/frontend.yaml", nodeIp)
	_, err = exec.Command("bash", "-c", cmd).CombinedOutput()
	if err != nil {
		panic(errors.Wrap(err, "Failed to Update domain_reference"))
	}

	// cmd = fmt.Sprintf("sed -i 's/monitoring-webhook.example.com/%v/' ./data/helm/values/spaceone/minimal.yaml", monitoringWebhookDomainName)
	// _, err = exec.Command("bash", "-c", cmd).CombinedOutput()
	// if err != nil {
	// 	panic(errors.Wrap(err, "Failed to Update monitoring-webhook domain"))
	// }

	// Update configmap
	Upgrade()

	// To mount the updated configmap to console pod
	_restartConsolePod()

	hostSetMsg := fmt.Sprintf(`
****************************************************************************************

'SpaceONE deploy' does not provide ingress-controller and ingress resource.
Access service endpoints directly from your browser.

- Console endpoint       http://%[1]v:%[2]v

****************************************************************************************`,nodeIp, consoleNodePort)

	log.Println(hostSetMsg)
}

func _getNodeIp() string {
	cmd := "kubectl get nodes `kubectl get nodes | grep -v NAME | awk '{print $1}' | head -1` --output=custom-columns='IP:.status.addresses[0].address' | tail -1"

	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(errors.Wrap(err, "Failed to get node ip"))
	}

	nodeIp := strings.TrimSuffix(string(output), "\n")

	return nodeIp
}

func _getNodePort(ServiceName string) string {
	cmd := fmt.Sprintf("kubectl get svc %v -n spaceone --output=custom-columns='nodePort:.spec.ports[0].nodePort' | tail -1", ServiceName)

	output, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		panic(errors.Wrap(err, "Failed to get node ip"))
	}

	NodePort := strings.TrimSuffix(string(output), "\n")

	return NodePort

}


