---
title: "Ditch the Gliffy, Excalidraw, and Visio and Begin Modelling as Code with Structurizr"
date: 2025-05-4T01:30:00Z
draft: false # publish
tags: ["Model as Code", "Diagramming", "Architecture"]
---

<img src="/images/model-as-code.png" alt="Model as Code">

## 

Tired of architecture diagrams that are perpetually out-of-date, inconsistent, or locked away in proprietary tools? Do you find yourself dreading the task of updating that Visio diagram after a minor infrastructure change? There's a better way: **Model as Code**. By defining your architecture using a textual Domain-Specific Language (DSL), you can version control, automate, and maintain your diagrams with the same rigor as your application code. This post explores how to use Structurizr and its DSL to create AWS deployment diagrams.

### Overview: C4, Structurizr, and Diagramming Tools

Before diving into the DSL, let's clarify some concepts:

1.  **The C4 Model:** Created by Simon Brown, the C4 model provides a simple, hierarchical way to think about and visualize software architecture at different levels of abstraction:
    *   **Level 1: System Context:** Shows your system in relation to users and other systems.
    *   **Level 2: Containers:** Zooms into your system, showing deployable/runnable units (web apps, APIs, databases, microservices).
    *   **Level 3: Components:** Zooms into a container, showing its internal code building blocks.
    *   **Level 4: Code:** (Optional) Zooms into a component, showing UML class diagrams, etc.
    Structurizr is primarily focused on Levels 1-3 and adds **Deployment diagrams** to show how containers map to infrastructure.

2.  **Structurizr:** A collection of tools (libraries, DSL, web application) built around the C4 model. It allows you to define your architecture elements (Software Systems, Containers, Components, People, Deployment Nodes) and their relationships *once* in a central model. From this model, you can generate multiple views, including deployment diagrams.

3.  **How it Differs from Diagramming Tools:**
    *   **Model-Based vs. Drawing-Based:** Tools like Visio, Gliffy, or Excalidraw are essentially drawing tools. You draw boxes and lines, which have no inherent meaning beyond their visual representation. Structurizr is model-based; you define *elements* and *relationships*, and the tool *renders* views based on that underlying model.
    *   **Consistency:** Because all views derive from one model, they are inherently consistent. Changing an element name in the model updates it everywhere.
    *   **Version Control:** The DSL is plain text, perfect for Git. You can track changes, revert, branch, and collaborate just like code.
    *   **Automation:** DSL files can be generated, validated, and diagrams exported as part of CI/CD pipelines.
    *   **Abstraction:** Easily generate different views (e.g., just the containers, or the full deployment) from the same model without redrawing.

### Building the AWS Deployment Diagram: Step-by-Step

Let's break down the provided Structurizr DSL example to see how we model an AWS deployment architecture.

**Stage 1: Workspace and Identifiers**

We start by defining the workspace and setting an identifier strategy.

```structurizr
workspace "Amazon Web Services Example" "AWS deployment architecture." {

    !identifiers hierarchical // Use hierarchical identifiers (e.g., system/container)

    model {
        // Model elements go here...
    }

    views {
       // View definitions go here...
    }
}
```

*   `workspace`: The top-level container for your model and views. It takes a name and optional description.
*   `!identifiers hierarchical`: Tells Structurizr to generate identifiers based on the element's position in the hierarchy. This is useful for referring to elements later.
*   `model {}`: The block where we define all the logical software elements and the deployment environments.
*   `views {}`: The block where we define which diagrams (views) to generate from the model.

**Stage 2: Defining the Logical Model (Software System & Containers)**

Before modeling the deployment, we need a logical representation of the software being deployed. Here, we define a software system ("Reference") containing several containers (applications and database schemas).

```structurizr
        x = softwaresystem "Reference" { // Define the overall software system

            // Define logical containers within the system
            db1 = container "Database Schema" {
                tags "Database"
            }
            db2 = container "Database Schema2" {
                tags "Database"
            }
            proxy1 = container "Proxy1" {
                technology "Proxy"
                tags "Application"
            }
            wa1 = container "Web Application1" {
                technology "Java and Spring Boot"
                tags "Application"
            }
            // Define relationships between logical containers
            proxy1 -> wa1 "http"
            wa1 -> db1 "Reads from and writes to" "TLS"

            proxy2 = container "Proxy2" {
                technology "Proxy"
                tags "Application"
            }
            wa2 = container "Web Application2" {
                technology "Java and Spring Boot"
                tags "Application"
            }
            // Define relationships
            proxy2 -> wa2 "http"
            wa2 -> db1 "Reads from and writes to" "TLS" // Note: both apps use db1
        }
```

*   `softwaresystem`: Represents the highest level of abstraction for the system we are modeling. We assign it to the variable `x` for easier reference.
*   `container`: Represents a deployable/runnable unit within the software system (like a web app, API, database schema, microservice). We assign names like `db1`, `proxy1` for reference.
*   `technology`: Specifies the technology used by the container.
*   `tags`: Used to categorize elements for styling or filtering views.
*   `->`: Defines a relationship between two elements, including an optional description and technology/protocol.

**Stage 3: Defining the Deployment Environment**

Now we define the target deployment environment ("Production") and start modeling the infrastructure hierarchy.

```structurizr
        prod = deploymentEnvironment "Production" { // Define the environment
            // Top-level node representing the cloud provider
            deploymentNode "Amazon Web Services" {
                tags "Amazon Web Services - Cloud"

                // Node representing the AWS Region
                region = deploymentNode "ap-southeast-2" {
                    tags "Amazon Web Services - Region"

                    // Infrastructure and nodes within the region go here...

                } // End Region
            } // End AWS Account/Cloud
        } // End Deployment Environment
```

*   `deploymentEnvironment`: A top-level element representing where the software is deployed (e.g., "Development", "Staging", "Production").
*   `deploymentNode`: Represents a unit of infrastructure, like a physical server, virtual machine, container host (like an EC2 instance), or a logical grouping (like an AWS Region or Account). They can be nested to show hierarchy. We assign the region node to the variable `region`.

**Stage 4: Modeling Core AWS Infrastructure (DNS, LB)**

Inside the Region node, we define key infrastructure components like Route 53 and the NLB.

```structurizr
                    // Node representing DNS service
                    dns = infrastructureNode "DNS" {
                        technology "Route 53"
                        description "Host based routing for incoming requests"
                        tags "Amazon Web Services - Route 53"
                    }

                    // Node representing the Load Balancer
                    lb = infrastructureNode "Network Load Balancer" {
                        technology "Network Load Balancer"
                        description "Automatically distributes incoming application traffic."
                        tags "Amazon Web Services - Elastic Load Balancing Network Load Balancer"
                        // Relationship: DNS forwards to LB
                        dns -> this "Forwards requests to" "HTTPS"
                    }
```

*   `infrastructureNode`: Represents supporting infrastructure that doesn't directly host containers but is part of the deployment environment (e.g., load balancers, DNS, firewalls, message queues).
*   `this`: A keyword used within a node definition to refer to the node itself when defining relationships.

**Stage 5: Modeling Compute (ASG, AZs, EC2, Pods)**

We model the compute layer, nesting Availability Zones (AZs), EC2 instances, and conceptual "POD" nodes within an Auto Scaling Group.

```structurizr
                    // Node representing the Auto Scaling Group
                    deploymentNode "Autoscaling group" {
                        tags "Amazon Web Services - Auto Scaling"

                        // Node representing Availability Zone 1
                        deploymentNode "AZ 1" {
                            tags "Amazon Web Services - Availability Zone"

                            // Node representing an EC2 Instance
                            deploymentNode "Amazon EC2 1" {
                                tags "Amazon Web Services - EC2"

                                // Node representing a K8s Pod or similar container host
                                deploymentNode "POD" {
                                    tags "Container" // Used for styling/grouping

                                    // Container instances go here...
                                }
                            }
                        } // End AZ 1

                        // Node representing Availability Zone 2
                        deploymentNode "AZ 2" {
                            tags "Amazon Web Services - Availability Zone"

                            // Node representing another EC2 Instance
                            deploymentNode "Amazon EC2 x" { // Name implies multiple/generic
                                tags "Amazon Web Services - EC2"

                                // Node representing a Pod in AZ 2
                                deploymentNode "POD" {
                                    tags "Container"

                                     // Container instances go here...
                                }
                            }
                        } // End AZ 2
                    } // End Autoscaling group
```

*   Nesting `deploymentNode` clearly shows the hierarchy: ASG > AZ > EC2 > POD.

**Stage 6: Deploying Container Instances (Applications)**

This is the crucial step where we link the *logical* containers (from Stage 2) to the *physical* deployment nodes (from Stage 5). We use `containerInstance` to show *instances* of our application containers running within the PODs.

```structurizr
                                // Inside the first POD in AZ 1
                                deploymentNode "POD" {
                                    tags "Container"

                                    // Instance of the logical proxy1 container
                                    proxyInstance = containerInstance x.proxy1 {
                                        // Relationship: LB forwards to this specific instance
                                        lb -> this "Forwards requests to" "HTTPS"
                                    }
                                    // Instance of the logical wa1 container
                                    webApplicationInstance = containerInstance x.wa1
                                }
```

```structurizr
                                // Inside the second POD in AZ 2
                                deploymentNode "POD" {
                                    tags "Container"

                                    // Instance of the logical proxy2 container
                                    proxyInstance = containerInstance x.proxy2 {
                                        // Relationship: LB also forwards here
                                        lb -> this "Forwards requests to" "HTTPS"
                                    }
                                    // Instance of the logical wa2 container
                                    webApplicationInstance = containerInstance x.wa2
                                }
```

*   `containerInstance`: Represents an instance of a specific logical `container` running on a specific `deploymentNode`.
*   `x.proxy1`, `x.wa1`, etc.: We use the hierarchical identifiers (enabled by `!identifiers hierarchical`) and the variable `x` (assigned to the software system) to refer back to the logical containers defined earlier.
*   Relationships (`lb -> this`) now target these specific running instances.

**Stage 7: Modeling the Database (RDS, Instances)**

We model the RDS deployment similarly, showing the overall service and instances within different AZs for high availability.

```structurizr
                    // Node representing the RDS service/cluster
                    deploymentNode "Amazon RDS" {
                        tags "Amazon Web Services - RDS"

                        // Node representing the AZ for the active instance
                        deploymentNode "AZ 1" {
                            tags "Amazon Web Services - Availability Zone"
                            // Node representing the specific instance
                            deploymentNode "Active" {
                                tags "Amazon Web Services - Aurora PostgreSQL Instance"

                                // Database container instance goes here...
                            }
                        } // End AZ 1 (RDS)

                        // Node representing the AZ for the passive instance
                        deploymentNode "AZ 2" {
                            tags "Amazon Web Services - Availability Zone"
                             // Node representing the specific instance
                            deploymentNode "Passive" {
                                tags "Amazon Web Services - Aurora PostgreSQL Instance"

                                // Database container instance goes here...
                            }
                        } // End AZ 2 (RDS)
                    } // End Amazon RDS
```

*   Again, `deploymentNode` nesting shows the structure: RDS Service > AZ > Specific DB Instance Node.

**Stage 8: Deploying Database Container Instances**

We map the logical database schema containers (`db1`, `db2`) to their respective RDS instance nodes using `containerInstance`.

```structurizr
                                // Inside the "Active" RDS instance node
                                deploymentNode "Active" {
                                    tags "Amazon Web Services - Aurora PostgreSQL Instance"

                                    // Instance of the logical db1 container schema
                                    databaseInstance = containerInstance x.db1
                                }
```

```structurizr
                                // Inside the "Passive" RDS instance node
                                deploymentNode "Passive" {
                                    tags "Amazon Web Services - Aurora PostgreSQL Instance"

                                    // Instance of the logical db2 container schema
                                    databaseInstance = containerInstance x.db2
                                }
```

*   `containerInstance x.db1`: Deploys the `db1` schema onto the "Active" RDS node.
*   `containerInstance x.db2`: Deploys the `db2` schema onto the "Passive" RDS node. (Note: The logical model showed `wa2` connecting to `db1`, so this mapping of `db2` might be an inconsistency in the original example DSL or represent a standby copy).

**Stage 9: Defining the View**

Here we specify *which* diagram we want to generate. We create a deployment view showing the "Reference" system (`x`) deployed into the "Production" environment (`prod`).

```structurizr
    views {
        // Define a deployment view for system 'x' in environment 'prod'
        deployment x prod "AmazonWebServicesDeployment" {
            include * // Include all elements relevant to this deployment view
            autolayout tb // Apply automatic layout (Top-Bottom)
        }

        // Style includes go here...
    }
```

*   `deployment <Software System> <Deployment Environment> <Key>`: Defines a deployment view.
*   `include *`: A simple way to include all elements from the specified environment and instances of the specified system. You can use more specific `include` or `exclude` rules.
*   `autolayout tb`: Specifies the automatic layout direction (Top-Bottom). `lr` (Left-Right) is another common option.

**Stage 10: Styling and Themes**

Finally, we include external styles and themes to make the diagram look good, often leveraging predefined AWS icons.

```structurizr
        // Include custom styles (optional, could define styles inline)
        !include styles.dsl

        // Apply a predefined theme for AWS icons and colours
        themes https://static.structurizr.com/themes/amazon-web-services-2023.01.31/theme.json
    } // End Views
```

*   `!include`: Imports definitions from another DSL file (useful for sharing styles).
*   `themes`: Applies predefined visual styles (colors, icons, shapes) from a URL or local file. This uses the official AWS theme.

### Conclusion

By defining our AWS infrastructure and application deployment using the Structurizr DSL, we've created a "model as code". This text-based model provides numerous advantages over manual diagramming:

*   **Version Controlled:** Check it into Git alongside your application and infrastructure code.
*   **Consistent:** All diagrams are generated from a single source of truth.
*   **Maintainable:** Updates are text edits, easily diffed and reviewed.
*   **Automatable:** Diagram generation can be part of your CI/CD pipeline.
*   **Clear:** The DSL encourages explicit definition of elements, relationships, and deployment mappings.

While there's a learning curve compared to drag-and-drop tools, the long-term benefits in clarity, consistency, and maintainability make Structurizr DSL a powerful approach for modeling complex cloud architectures.

---

**Reference:** For more Structurizr examples and inspiration, check out this GitHub repository: [https://github.com/tomconn/structurizr/](https://github.com/tomconn/structurizr/)