---
title: "How I passed Istio Certified Associate, ICA"
date: 2025-09-13T10:30:00Z
draft: false # publish
tags: ["Istio", "Service Mesh", "Kubernetes"]
---

<img src="ica.jpg" alt="ICA attained" style="display: block; margin: auto;">

The [Istio Certified Associate, ICA](https://training.linuxfoundation.org/certification/istio-certified-associate-ica/) is a challenging and practical hands on exam. To help me learn a capability I like the idea of a exam based goal, it's achievable and ensures I attain a strong understanding of the system.  

## Building a question and problem solving routine
I used the following workflow, to methodically tackle each question. I found the routine helpful as it developed muscle memory and was one less thing to have to remember. 

- At the start of each question there is a hyperlink to the relevant istio documentation, I strongly advise using this.
- I had a single terminal window open, and at the start of each question, used the provided `ssh <server>` to login to the server.
- If the question required investigation, I would gather information and use this to inform the answer.
- Using the provided VS Chromium, I created a new tab for each question. I copied the relevant manifests from the documentation, modified to solve the question. Once happy I copied the manifests to the clipboard.
- In the Terminal, I used vim to create a yaml file, and pasted the saved manifest (Ctrl, Shift, V) and saved (Shift ZZ).
- Some questions required editing a resource, in this case I still used the editor for the manifest snippet and pasted into the resource and saved.
- On the command line I executing either istioctl and/or kubectl, to apply the changes. Any errors I fixed in VS Chromium and repeated above steps.
- If the question provides a curl or cli command to validate, do execute it, if it fails validation, I gave myself a minute to investigate but if I couldn't resolve I'd flag the question and move on to the next one.

## Breaking down the Domains & Competencies

### Installation, Upgrades, and Configuration – 20%

Installing Istio with istioctl or Helm
- Be very familiar with iostioctl install/analyze options.
Installing Istio in Sidecar or Ambient Mode
- Ensure you you understand enabling/disabling the sidecar on pods and namespaces. 
Customizing your Istio Installation
- Ensure you understand the IstioOperator and customizing the components.
Upgrading Istio (Canary, In-Place)
- Practice Istio canary and in-place upgrades, I used my Mac to practice the upgrade using [Istio on Kind practice](http://github.com/tomconn/istio-on-kind).


### Traffic Management – 35%

Configuring Ingress and Egress Traffic
Configuring Routing within a Service Mesh
Defining Traffic Policies with Destination Rules
Configuring Traffic Shifting
Connecting In-Mesh Workloads to External Workloads and Services
Using Resilience Features (circuit breaking, failover, outlier detection, timeouts, retries)
Using Fault Injection

- This section is all about being familiar with the Istio resources. I practiced this over and over using, this slightly outdated but still brilliant [Killercoda Istio practice](https://killercoda.com/ica). Again I built up a strong familiarity, on these areas, and could lean into the presented problems. 

### Securing Workloads – 25% 

Configuring Authorization
Configuring Authentication (mTLS, JWT)
Securing Edge Traffic with TLS

- Again this section is all about being familiar with the Istio resources. As mentioned I used the killercoda practice exams and the istio help pages to solve the problems.

### Troubleshooting – 20%

Troubleshooting Configuration
Troubleshooting the Mesh Control Plane
Troubleshooting the Mesh Data Plane

- I found this to be the toughest area. Under exam and time pressure, you need to have a method to help diagnose the issue(s). The advice I have is become familiar with the Istio troubleshooting documentation. Use `istioctl analyze`, `kubectl logs`, `kubectl get po/deploy POD --o yaml` and `kubectl rollout restart` to diagnose and solve. Easy to say, but stay focused, don't panic and timebox and move on. 

## Summary
There were 16 questions, in the exam I took, I'd completed the first pass in about 90 minutes. This left 30 minutes to review flagged questions and figure out the troubleshooting questions. I actually spent the majority of this time on troubleshooting.
This was a tougher exam that the associate label suggests. But it's worth it if your organization is currently using or planning to use Istio.
Finally I attained the [credly cert](https://www.credly.com/badges/42e6f473-35a6-4623-9dbe-7173b6126ac5/linked_in_profile).

## Resources
* [ICA updates](https://training.linuxfoundation.org/istio-certified-associate-ica-program-changes)
* [Killercoda Istio practice](https://killercoda.com/ica)
* [Istio on Kind practice](http://github.com/tomconn/istio-on-kind)
* [My certification](https://www.credly.com/badges/42e6f473-35a6-4623-9dbe-7173b6126ac5/linked_in_profile)
* [David Watts - prep](https://medium.com/@wattsdave/istio-certified-associate-ica-exam-prep-51b59bdd372f)
* [David Watts - study notes](https://medium.com/@wattsdave/istio-certified-associate-ica-exam-prep-51b59bdd372f)
* [Slack - #istio-exam-study-group](https://cloud-native.slack.com/archives/C05TRTYKZH9)
