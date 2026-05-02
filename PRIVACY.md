Privacy Policy
==============

Effective date: April 27, 2026

Summary
-------

OSDCloud is a PowerShell module that runs locally. Some workflows send deployment analytics events during deployment tasks. The module also transmits data when you invoke commands that connect to external services (for example, downloading operating system or driver content).

Deployment analytics
--------------

During workflow task execution, OSDCloud sends a deployment event to PostHog. The event includes:

- A hashed device identifier derived from the device UUID (see below)
- Device details (manufacturer, model, SKU, system family)
- BIOS details (firmware type, release date, SMBIOS version)
- Keyboard name and layout
- OS details (name, version, build, edition, language)
- Workflow details (workflow name, task name, driver pack name, OS selection)
- Module version and deployment phase (WinPE or Windows)

**No personal identifying information is captured.** The analytics do not include usernames, email addresses, device serial numbers, computer names, IP addresses (beyond standard HTTP headers), or any other data that could identify an individual or specific device.

**Device identifier hashing**

The device identifier is derived from the device UUID obtained from WMI. Before transmission the UUID is hashed with **SHA-256** and the resulting hex digest is used as the identifier. This process is one-way: the original UUID cannot be recovered from the hash.

If the UUID is empty or unavailable (for example in some virtual machine environments), a random GUID is generated for that session and used in its place.

What data may be shared
-----------------------

- Network metadata (IP address, request headers) may be logged by third-party services you connect to.
- Content downloads may include standard HTTP request details required by those services.
- Deployment analytics events include the fields described above and a timestamp.
- Analytics events are sent to PostHog over HTTPS with a two-second timeout. If the request fails the failure is logged at verbose level and deployment continues.

External services
-----------------

OSDCloud may interact with external services when you choose to download content, update the module, or run workflows. Those services have their own privacy policies. Examples include:

- **Microsoft Update Catalog** — used to download OS images, firmware, and driver updates. See the [Microsoft Privacy Statement](https://privacy.microsoft.com/privacystatement).
- **GitHub** — project hosting and issue tracking. See the [GitHub Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).
- **PowerShell Gallery** — module distribution. Governed by the Microsoft Privacy Statement.
- **OEM driver sites** — Dell, HP, Lenovo, and Panasonic driver pack catalogs are fetched from vendor-hosted servers. Consult each vendor's privacy policy.
- **PostHog** — deployment analytics. Events are sent to `https://us.i.posthog.com`. See the [PostHog Privacy Policy](https://posthog.com/privacy).

Your choices
------------

- You control when network requests happen by choosing which commands to run.
- Analytics events are sent only when a deployment workflow task executes (`Invoke-OSDCloudWorkflowTask`). Commands that only display information (such as `Show-OSDCloudDeviceInfo` or `Get-OSDCloudModuleVersion`) do not send analytics.
- To avoid analytics entirely, do not run deployment workflow commands (`Deploy-OSDCloud`, `Invoke-OSDCloudWorkflowTask`).

Contact
-------

For questions or concerns, open an issue at <https://github.com/OSDeploy/OSDCloud/issues>.
