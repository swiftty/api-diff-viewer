PACKAGE_DIR := api-diff-viewer
PROJECT_NAME := api-diff-viewer
XCODE_PROJECT := $(PROJECT_NAME).xcodeproj
XCUSERDATA_DIR := $(XCODE_PROJECT)/project.xcworkspace/xcuserdata/$(shell whoami).xcuserdatad
XCSHAREDDATA_DIR := $(XCODE_PROJECT)/project.xcworkspace/xcshareddata

SWIFT = swift$(1) --package-path $(PACKAGE_DIR) --build-path DerivedData/$(PROJECT_NAME)/SourcePackages

.PHONY: project
project:
	@$(call SWIFT, package) plugin --allow-writing-to-directory . xcodegen

	@mkdir -p $(XCUSERDATA_DIR)
	@cp -f $(XCSHAREDDATA_DIR)/WorkspaceSettings.xcsettings $(XCUSERDATA_DIR)/WorkspaceSettings.xcsettings

.PHONY: format
format:
	@$(call SWIFT, package) plugin --allow-writing-to-package-directory --allow-writing-to-directory ../ swiftlint lint --fix --working-directory ../

.PHONY: unittest
unittest:
	$(call SWIFT, test)

.PHONY: resolve
resolve:
	cp -f $(XCSHAREDDATA_DIR)/swiftpm/Package.resolved $(PACKAGE_DIR)/Package.resolved
	$(call SWIFT, package) resolve
	cp -f $(PACKAGE_DIR)/Package.resolved $(XCSHAREDDATA_DIR)/swiftpm/Package.resolved
