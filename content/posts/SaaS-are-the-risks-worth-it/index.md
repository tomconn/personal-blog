---
title: "Is Your SaaS Vendor Secretly Holding the Keys to Your Kingdom? (Probably Not, But Let's Check Anyway!)"
date: 2025-04-29T19:30:00Z
draft: false # publish
tags: ["SaaS", "Software as a Service", "Supply Chain Security"]
---

<img src="hacker-between-factories.png" alt="Hacker supply chain hack">

{{</ img src="hacker-between-factories.png" alt="Hacker supply chain hack" />}}

Software as a Service (SaaS) is fantastic, isn't it? Click a button, enter a credit card, and *poof* – instant productivity, collaboration, or cat video enhancement. It's like magic, but with more invoices. We offload the hassle of installation, patching, and keeping the server room hamsters fed. But with great convenience comes... well, not *great* responsibility for us, that's the point! But it *does* come with inherent risks.

What happens when the boffins behind the curtain (your SaaS vendor) have a bad day? Maybe a disgruntled apprentice leaves a backdoor open, or perhaps sophisticated trolls (aka bad actors) breach their defenses. Suddenly, that convenient service isn't just serving you; it might be serving up your data to the highest bidder. Even worse, sometimes the vendor, in their infinite wisdom (or desire for easy integration), asks for permissions akin to handing over the keys to your entire digital estate, just so their app can check the weather forecast. A little overkill, perhaps? We need to ensure our reliance on SaaS doesn't turn into a SCaaS (Security Catastrophe as a Service).

## Why Are We Even Talking About This? SaaS vs. The Old Ways

This blog post isn't about scaring you back to installing software from floppy disks (remember those?). It's about understanding the specific risks SaaS introduces compared to traditional, self-installed software and how to manage them effectively.

When you install software yourself, *you* control the environment, the network access, the patching schedule (for better or worse), and the direct security posture. With SaaS, you're outsourcing much of that control, trusting the vendor to get it right. This trust, however, can be misplaced, leading to significant consequences.

**Recent Examples (The Not-So-Funny Part):**

 *  **Okta Support System Breach (Late 2023):** Threat actors compromised Okta's support case management system using stolen credentials. This allowed them to view files uploaded by certain customers, including session tokens that could potentially be hijacked to impersonate legitimate users within those customer organizations. This highlights how a breach in a *support* system of a critical identity provider can cascade down to its customers, impacting *their* security.
 *  **MOVEit Transfer Vulnerability Exploits (Mid-2023):** While MOVEit is often used as self-hosted software, many organizations consumed it via SaaS providers or had partners using it who suffered breaches. A zero-day vulnerability allowed widespread data theft across hundreds, if not thousands, of organizations globally. Customers of affected companies faced reputational damage, potential regulatory fines (GDPR, HIPAA, etc.), and significant incident response costs, even if their *direct* systems weren't breached – their data held by the SaaS or a partner using it was.

These incidents underscore that a vendor's security failure can quickly become *your* security failure, impacting reputation, finances, and regulatory standing.

## Taming the SaaS Beast: Principles and Practical Steps

Okay, enough doom and gloom. How do we use SaaS safely and sleep (mostly) soundly? It boils down to diligence, control, and asking the right questions.

**Core Principles:**

*   **Verify, Then Trust (But Keep Verifying):** Don't take vendor claims at face value.
*   **Least Privilege & Segregation:** Give only what's needed, separate responsibilities.
*   **Control Your Data:** Maintain sovereignty over your sensitive information.
*   **Assess Risk Realistically:** Align controls with data/system criticality.
*   **Assume Breach Potential:** Design for resilience.

**Mitigation Checklist & Activities:**

*  **Vendor Validation - The Minimum Bar (SOC 2 Type 2 & ISO 27001):**
    *   **Requirement:** Insist on seeing recent SOC 2 Type 2 reports and ISO 27001 certification (or equivalent, like relevant NIST frameworks).
    *   **What they tell you:** These demonstrate the vendor *has* security controls and processes, and (for SOC 2 Type 2) that they were operating effectively over a period.
    *   **The Limits (Crucial!):**
        *   **Scope:** Does the report scope cover the *specific* service you are using and the controls relevant to *your* risks (e.g., data segregation, access control)? Often, critical parts might be excluded.
        *   **Point-in-Time:** ISO 27001 is a snapshot; SOC 2 Type 2 looks back, but doesn't guarantee future performance.
        *   **Not Your Controls:** They attest to the *vendor's* controls, not necessarily how those controls protect *your specific instance* or integrate securely with *your environment*.
    *   **Action:** Review the *full* reports (not just the certificate). Pay attention to exceptions, auditor opinions, and the scope description. Use these as a *starting point* for deeper questions.

*  **Preventing Overly Permissive Access:**
    *   **Problem:** SaaS vendors often ask for broad permissions in your cloud environment (e.g., AWS, Azure, GCP) for "ease of integration."
    *   **Mitigation:**
        *   **Least Privilege:** Scrutinize every requested permission. Use dedicated IAM roles or service principals with the absolute minimum permissions required for the SaaS to function. Avoid granting global admin or broad read/write access. Regularly audit these permissions.
        *   **Segregation of Duties (SoD):** Ensure the entity (user or service account) connecting the SaaS cannot also perform highly sensitive actions within your environment. If the SaaS needs to trigger an action, it should ideally request it via an API that a separate, internally controlled process authorizes and executes.

*  **Controlling Execution - Don't Let the SaaS Run Wild:**
    *   **Problem:** A compromised SaaS platform might attempt to execute malicious commands or access unauthorized systems within your network via its established connection.
    *   **Mitigation:**
        *   **Network Segregation:** Place the integration point for the SaaS (e.g., an API gateway, a specific VM) in a segregated network zone with strict firewall rules. It should only be able to reach the specific internal resources it *needs*, nothing more.
        *   **Internal Authorization:** For critical actions initiated *by* the SaaS (e.g., deploying resources, modifying critical data), don't allow direct execution. Design the workflow so the SaaS request triggers an *internal* approval process (manual or automated) before your own controlled systems perform the action. The SaaS asks, your system vets and acts.

*  **Prefer Agent-Based Models (Outbound Connections):**
    *   **Model:** Instead of the SaaS platform initiating connections *into* your network (requiring open firewall ports and complex routing), use SaaS solutions that employ an agent running within your environment.
    *   **Benefit:** This agent initiates connections *outbound* to the SaaS platform. This is generally easier to secure:
        *   Reduces inbound attack surface (no open ports needed for the vendor).
        *   Less chance of misconfigured firewall rules allowing unwanted inbound access.
        *   You control the agent's environment and its outbound communication path (e.g., via proxy, specific egress rules).

*  **Data Sovereignty - Customer Managed Keys (CMK/BYOK):**
    *   **Problem:** Your data resides in the SaaS provider's infrastructure, encrypted by *their* keys. If they are compromised, your data might be exposed.
    *   **Mitigation:** Use SaaS providers that support Customer Managed Keys (CMK) or Bring Your Own Key (BYOK).
        *   **How it works:** You generate and manage the master encryption key within your own secure environment (e.g., AWS KMS, Azure Key Vault, Google Cloud KMS). The SaaS platform uses this key (via API calls you authorize) to encrypt and decrypt *your* data.
        *   **The "Kill Switch":** If the vendor is compromised or you terminate the service, you can revoke the SaaS platform's access to your key, rendering your data stored in their system cryptographically unusable. This gives you ultimate control over data remanence.

*  **Risk Assessment vs. Criticality:**
    *   **Question:** Does the risk posture of using this SaaS align with the criticality of the system or data involved?
    *   **Consider:**
        *   Is this system part of critical national infrastructure?
        *   Does it handle highly sensitive PII, financial data, or intellectual property?
        *   What are the regulatory implications of a breach via this vector?
    *   **Action:** If the risks associated with SaaS (even after mitigation) are too high for the system's function or data's sensitivity, **reconsider using SaaS for this specific purpose.** Explore options for self-hosted software. If you go self-hosted, negotiate a multi-year license and support agreement to ensure long-term viability and avoid vendor pressure to move to their SaaS offering later.

*  **Mandate Multi-Factor Authentication (MFA):**
    *   **Non-Negotiable:** Ensure MFA is enforced for *all* user access to the SaaS platform (admin and regular users).
    *   **Vendor Access:** Critically, ensure any accounts the *vendor* uses for support or management access also require MFA, ideally from devices managed by the vendor.
    *   **Your Integration Points:** Secure your own service accounts and administrative access related to the SaaS integration with strong credentials and MFA where applicable (e.g., console access).

*  **Understand the SaaS Architecture (Multi-Tenant vs. Single-Tenant):**
    *   **Multi-Tenant:** Most SaaS. You share underlying infrastructure resources with other customers. Cheaper, but relies heavily on the vendor's logical separation controls. A failure here *could* lead to cross-tenant data exposure. Ask the vendor how they *prove* tenant isolation, enforce least privilege internally, and segregate duties among their own operational staff.
    *   **Single-Tenant:** You get dedicated infrastructure resources. More expensive, generally better isolation, but still relies on vendor operational security.
    *   **Action:** Understand the model you're buying. If multi-tenant, probe deeper into their isolation controls during your vendor assessment. If single-tenant, understand how boundary controls are maintained.

## Summary: Stay Safe in the SaaS Seas

Using SaaS offers immense benefits, but it's not a "fire and forget" solution for security. The convenience comes with the responsibility of diligent vendor management and implementing robust controls at the integration points.

**Key Principles & Mitigants Recap:**

*   **Validate Vendors:** Go beyond the certificates (SOC 2, ISO 27001); understand their scope and limitations.
*   **Control Access:** Apply least privilege rigorously to vendor permissions in your environment. Segregate duties.
*   **Control Execution:** Use network segmentation and internal authorization for critical actions triggered by the SaaS. Prefer agent-based, outbound-only connection models.
*   **Control Data:** Employ Customer Managed Keys (CMK/BYOK) for sensitive data encryption.
*   **Assess Risk:** Align SaaS use with system/data criticality. Consider self-hosting for high-risk scenarios.
*   **Mandate MFA:** Everywhere, for everyone (users, admins, vendors).
*   **Understand Architecture:** Know the implications of multi-tenancy vs. single-tenancy.

By applying these principles and performing continuous monitoring, you can harness the power of SaaS while minimizing the risk of your vendor inadvertently (or via compromise) becoming your biggest security headache. Stay vigilant, ask tough questions, and keep those kingdom keys secure!