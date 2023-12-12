"To launch this infrastructure, execute the `launch.sh` script. Ensure that you have sudo access, or alternatively, modify the path specified in the `PRIVATE_KEY_FILE` environment variable if needed."

"This infrastructure, while functional, is intentionally kept simple for demonstration purposes. To enhance its robustness and maintainability, consider introducing additional variables for flexibility and automation. Furthermore, prioritize security enhancements, especially in the database subnet, to fortify the overall architecture. For a smoother execution"

As part of the initial implementation, I opted for the use of init scripts on EC2 instances to maintain simplicity. However, for future iterations and to improve deployment processes, I am exploring the integration of Ansible into the workflow. Ansible offers a more robust and flexible approach, allowing for seamless deployment of Docker containers and efficient configuration management on EC2 instances. This shift towards Ansible aims to enhance automation, scalability, and maintainability within the infrastructure.

- Infrastructure Monitoring Documentation
This document provides guidelines on monitoring the infrastructure created using Infrastructure as Code (IaC) for a basic ordering system. The infrastructure includes a frontend and backend application hosted on EC2 instances, and an RDS database connected with IAM authentication.

Monitoring Components
1. CloudWatch Metrics for EC2 Instances:
Metrics to Monitor:
CPU Utilization
Memory Utilization
Disk I/O
Network I/O
2. CloudWatch Metrics for RDS Instance:
Metrics to Monitor:
CPU Utilization
Freeable Memory
Database Connections
Disk I/O
Read/Write Latency
3. Custom Metrics:
Consider adding custom metrics for application-specific monitoring.
For example, monitor the number of orders processed, response time, etc.
4. CloudWatch Alarms:
Set up CloudWatch alarms based on thresholds for critical metrics.
Example: Trigger an alarm if CPU utilization on EC2 instances exceeds 80% for an extended period.
5. Logs:
Enable logs for both EC2 instances and RDS.
Stream logs to CloudWatch Logs for centralized log monitoring.
Log relevant application events, errors, and access logs.
6. Security Monitoring:
Enable AWS CloudTrail to log AWS API calls and monitor for suspicious activities.
Set up alerts for specific security-related events.
7. Docker Container Monitoring:
Utilize Docker monitoring tools like Prometheus and Grafana for container-level metrics.
Monitor container resource usage, errors, and restarts.
8. Application-Level Monitoring:
Implement application-level monitoring using tools like New Relic, Datadog, or custom metrics.
Monitor response times, error rates, and application-specific KPIs.
9. Uptime Monitoring:
Use external tools like AWS CloudWatch Synthetics, Pingdom, or UptimeRobot to monitor the availability of the frontend.
Implementation Details
1. CloudWatch Agent:
Install and configure the CloudWatch agent on EC2 instances for detailed system and application-level monitoring.
2. CloudWatch Logs Agent:
Install the CloudWatch Logs agent on EC2 instances and RDS to stream logs to CloudWatch Logs.
3. Alarms Configuration:
Define CloudWatch alarms based on the defined metrics and thresholds.
Establish notification actions for alarm triggers.
4. Docker Monitoring:
Implement Docker monitoring tools within the Dockerized application.
Configure Prometheus and Grafana to collect and visualize container metrics.
5. Application Monitoring Integration:
If using third-party application monitoring tools, integrate them into the application code or infrastructure.
6. Automation Script:
Provide a script for automating the setup and configuration of monitoring components.
Include instructions for running the script and configuring monitoring settings.
Conclusion
By implementing comprehensive monitoring, you ensure the health, performance, and security of your infrastructure. Regularly review and update monitoring configurations to adapt to changing application requirements and to address emerging issues proactively.