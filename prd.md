> **Project Update**: The repository is transitioning into a **Universal Container App Store**. This document describes the original Open WebUI Installer concept and is kept for historical reference.

⸻

📄 1. Title & Author
	•	Product Name: macOS Open WebUI Installer & Launcher
	•	Author: [Your Name], Product Manager
	•	Date: June 19, 2025
	•	Version: 0.1

⸻

🎯 2. Purpose & Scope

**Purpose**  
Provide macOS users with a seamless installation experience that automatically handles:  
	1.	Docker Desktop installation,
	2.	Ollama setup,
	3.	Docker Compose configuration for Open WebUI + Ollama, and
	4.	Creation and registration of a one-click launcher app to auto-run at login.

**Scope**  
	•	Support for macOS 12+.  
	•	Interactive GUI progress/status.  
	•	Optional packaging as .app (via Automator) or .pkg with launchd support.

⸻

👤 3. Stakeholders & Users  
	•	End-User: Tech-savvy Mac users who want hassle-free setup and daily access.  
	•	Engineering: Scripting the installer, Automator workflows, packaging.  
	•	QA: Validation across macOS versions; install/uninstall flows.  
	•	Support: Documentation, troubleshooting guides.

⸻

🧠 4. Background & Strategic Fit

With daily reliance on Open WebUI and Ollama, users waste time on manual setup and container management. This installer simplifies onboarding, improves adoption, and reduces support overhead. It aligns with user experience objectives for automation and ease.

⸻

🎯 5. Goals & Success Metrics  
	•	G1: Reduce setup time to under 5 minutes.  
	•	G2: Achieve zero support tickets for initial setup.  
	•	G3: Ensure ≥ 90% installation success rate across supported macOS versions.  
	•	G4: Users should access Open WebUI immediately after reboot without manual steps.

⸻

⚙️ 6. Functional Requirements (Must-Have)  
	1.	Dependency Installer  
		•	Detect Docker and Ollama; prompt download or install via Homebrew.  
	2.	Docker Compose Setup  
		•	Generate docker-compose.yml in a user-accessible directory.  
		•	Execute docker compose up -d.  
	3.	Automator App Generation  
		•	Bundle launcher .app that:  
		•	Launches Docker Desktop.  
		•	Waits for Docker to be ready.  
		•	Starts containers or uses docker compose.  
		•	Opens http://localhost:3000.  
	4.	Login Item Registration  
		•	Offer GUI checkbox to add launcher .app to Login Items.  
		•	Alternatively, use launchd plist option.  
	5.	Uninstaller  
		•	Provide a script or preference pane to remove all created components.

⸻

✅ 7. Non-functional Requirements  
	•	UX: GUI with clear progress/status.  
	•	Security: Scripts run locally with user consent; no elevated privileges beyond Homebrew install.  
	•	Performance: Total installation ≤ 5 minutes (incl. downloads).  
	•	Reliability: Retry mechanisms for network failures.  
	•	Compatibility: Test macOS 12+; Apple Silicon + Intel.

⸻

🗓️ 8. Timeline & Milestones

| Milestone                | Target Date     |
|--------------------------|----------------|
| MVP automation script    | July 10, 2025  |
| Automator GUI prototype  | July 20, 2025  |
| Login Item integration   | August 1, 2025 |
| Internal QA & bugfixing  | August 15, 2025|
| Beta release to users    | August 22, 2025|
| Final release and docs   | September 1, 2025|

⸻

🧩 9. Dependencies & Constraints  
	•	Dependencies: Homebrew, AppleScript/Automator, Docker, Ollama CLI.  
	•	Constraints: macOS user must grant permission for Login Item.  
	•	Assumptions: Users already have developer tools or Homebrew installed.

⸻

🛠️ 10. Edge Cases  
	•	Partial installation (Ollama/Docker missing).  
	•	Docker login loop/stuck on Apple launch.  
	•	Existing Login Item conflict; prompt user.

⸻

📏 11. Metrics & Success Criteria  
	•	Time-to-complete installer  
	•	Launcher Add Success % (tracked via user telemetry)  
	•	Autostart reliability (measured via user survey)  
	•	Support tickets related to install (should approach zero)

⸻

🔚 12. Out of Scope  
	•	Cross-platform support (Windows/Linux) — deferred to a later phase.  
	•	GUI management of containers beyond initial setup.  
	•	Updates/maintenance of installed Docker images (could be added later).  
**Note**: The CLI installer continues to support macOS and Linux and will be maintained alongside the new macOS app.

⸻

🚀 **Development Phases**

_Phase 1-3_ retain their original scope.  
_Phase 4_ introduces Windows & Linux support:  
  1. Adapt the container store to run on Windows and Linux.  
  2. Add CI jobs for those platforms.  
  3. Update tests accordingly.

⸻

🧑‍🎨 13. Next Steps  
	1.	Approve PRD and confirm scope.  
	2.	Assign engineering resource to scripting & Automator implementation.  
	3.	Begin GUI prototype and iterative testing.  
	4.	Plan beta testing with real users.

⸻

This PRD captures the end‑to‑end user journey and technical needs for a smooth, one-click macOS installer. Let me know if you’d like to expand the scope or adjust any sections!
