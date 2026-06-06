#!/usr/bin/env python3
"""
SolunumAI.xcodeproj Generator
Requires only Python 3 (already on macOS). No Homebrew / xcodegen needed.
Run: python3 generate_xcodeproj.py
"""
import os, pathlib, textwrap

ROOT = pathlib.Path(__file__).parent

# ── Fixed GUIDs ──────────────────────────────────────────────────────────────
# (stable so the project file is deterministic / diff-friendly)

G = {
    # Project & target scaffolding
    "PROJECT":                "AA0001000000000000000001",
    "TARGET":                 "AA0002000000000000000002",
    "SOURCES_PHASE":          "AA0003000000000000000003",
    "RESOURCES_PHASE":        "AA0004000000000000000004",
    "FRAMEWORKS_PHASE":       "AA0005000000000000000005",
    "TARGET_CFGLIST":         "AA0006000000000000000006",
    "PROJECT_CFGLIST":        "AA0007000000000000000007",
    "TARGET_DEBUG_CFG":       "AA0008000000000000000008",
    "TARGET_RELEASE_CFG":     "AA0009000000000000000009",
    "PROJECT_DEBUG_CFG":      "AA000A000000000000000010",
    "PROJECT_RELEASE_CFG":    "AA000B000000000000000011",
    # Groups
    "MAIN_GROUP":             "AA0010000000000000000020",
    "PRODUCTS_GROUP":         "AA0011000000000000000021",
    "APP_GROUP":              "AA0012000000000000000022",
    "VIEWS_GROUP":            "AA0013000000000000000023",
    "COMPONENTS_GROUP":       "AA0014000000000000000024",
    "MODELS_GROUP":           "AA0015000000000000000025",
    "SERVICES_GROUP":         "AA0016000000000000000026",
    "RESOURCES_GROUP":        "AA0017000000000000000027",
    # File refs — sources
    "REF_APP":                "AA0030000000000000000040",
    "REF_HOMEVIEW":           "AA0031000000000000000041",
    "REF_ANALYSISVIEW":       "AA0032000000000000000042",
    "REF_HISTORYVIEW":        "AA0033000000000000000043",
    "REF_EXERCISESVIEW":      "AA0034000000000000000044",
    "REF_RISKGAUGE":          "AA0035000000000000000045",
    "REF_AUDIOWAVEFORM":      "AA0036000000000000000046",
    "REF_BREATHINGANIM":      "AA0037000000000000000047",
    "REF_HEALTHTIPCARD":      "AA0038000000000000000048",
    "REF_ANALYSISRESULT":     "AA0039000000000000000049",
    "REF_CDCLASS":            "AA003A000000000000000049",
    "REF_CDPROPS":            "AA003B000000000000000049",
    "REF_APISERVICE":         "AA0040000000000000000050",
    "REF_AUDIORECORDER":      "AA0041000000000000000051",
    "REF_COREDATA_SVC":       "AA0042000000000000000052",
    # File refs — resources
    "REF_ASSETS":             "AA0050000000000000000060",
    "REF_XCDATAMODELD":       "AA0051000000000000000061",
    "REF_INFOPLIST":          "AA0052000000000000000062",
    # File refs — product
    "REF_PRODUCT":            "AA0060000000000000000070",
    # File refs — frameworks
    "REF_AVFOUNDATION":       "AA0070000000000000000080",
    "REF_COREDATA_FW":        "AA0071000000000000000081",
    "REF_CHARTS_FW":          "AA0072000000000000000082",
    # Build files — sources
    "BF_APP":                 "AA0080000000000000000090",
    "BF_HOMEVIEW":            "AA0081000000000000000091",
    "BF_ANALYSISVIEW":        "AA0082000000000000000092",
    "BF_HISTORYVIEW":         "AA0083000000000000000093",
    "BF_EXERCISESVIEW":       "AA0084000000000000000094",
    "BF_RISKGAUGE":           "AA0085000000000000000095",
    "BF_AUDIOWAVEFORM":       "AA0086000000000000000096",
    "BF_BREATHINGANIM":       "AA0087000000000000000097",
    "BF_HEALTHTIPCARD":       "AA0088000000000000000098",
    "BF_ANALYSISRESULT":      "AA0089000000000000000099",
    "BF_CDCLASS":             "AA0089100000000000000099",
    "BF_CDPROPS":             "AA0089200000000000000099",
    "BF_APISERVICE":          "AA0090000000000000000100",
    "BF_AUDIORECORDER":       "AA0091000000000000000101",
    "BF_COREDATA_SVC":        "AA0092000000000000000102",
    # Build files — resources
    "BF_ASSETS":              "AA00A0000000000000000110",
    "BF_XCDATAMODELD":        "AA00A1000000000000000111",
    # Build files — frameworks
    "BF_AVFOUNDATION":        "AA00B0000000000000000120",
    "BF_COREDATA_FW":         "AA00B1000000000000000121",
    "BF_CHARTS_FW":           "AA00B2000000000000000122",
}

# ── pbxproj content ──────────────────────────────────────────────────────────

def pbxproj():
    return f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
\t\t{G['BF_APP']} /* SolunumAIApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_APP']}; }};
\t\t{G['BF_HOMEVIEW']} /* HomeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_HOMEVIEW']}; }};
\t\t{G['BF_ANALYSISVIEW']} /* AnalysisView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_ANALYSISVIEW']}; }};
\t\t{G['BF_HISTORYVIEW']} /* HistoryView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_HISTORYVIEW']}; }};
\t\t{G['BF_EXERCISESVIEW']} /* ExercisesView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_EXERCISESVIEW']}; }};
\t\t{G['BF_RISKGAUGE']} /* RiskGaugeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_RISKGAUGE']}; }};
\t\t{G['BF_AUDIOWAVEFORM']} /* AudioWaveformView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_AUDIOWAVEFORM']}; }};
\t\t{G['BF_BREATHINGANIM']} /* BreathingAnimationView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_BREATHINGANIM']}; }};
\t\t{G['BF_HEALTHTIPCARD']} /* HealthTipCardView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_HEALTHTIPCARD']}; }};
\t\t{G['BF_ANALYSISRESULT']} /* AnalysisResult.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_ANALYSISRESULT']}; }};
\t\t{G['BF_CDCLASS']} /* AnalysisEntity+CoreDataClass.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_CDCLASS']}; }};
\t\t{G['BF_CDPROPS']} /* AnalysisEntity+CoreDataProperties.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_CDPROPS']}; }};
\t\t{G['BF_APISERVICE']} /* APIService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_APISERVICE']}; }};
\t\t{G['BF_AUDIORECORDER']} /* AudioRecorderService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_AUDIORECORDER']}; }};
\t\t{G['BF_COREDATA_SVC']} /* CoreDataService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {G['REF_COREDATA_SVC']}; }};
\t\t{G['BF_ASSETS']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {G['REF_ASSETS']}; }};
\t\t{G['BF_XCDATAMODELD']} /* SolunumAI.xcdatamodeld in Resources */ = {{isa = PBXBuildFile; fileRef = {G['REF_XCDATAMODELD']}; }};
\t\t{G['BF_AVFOUNDATION']} /* AVFoundation.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {G['REF_AVFOUNDATION']}; }};
\t\t{G['BF_COREDATA_FW']} /* CoreData.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {G['REF_COREDATA_FW']}; }};
\t\t{G['BF_CHARTS_FW']} /* Charts.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {G['REF_CHARTS_FW']}; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{G['REF_PRODUCT']} /* SolunumAI.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SolunumAI.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{G['REF_INFOPLIST']} /* Info.plist */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{G['REF_ASSETS']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{G['REF_XCDATAMODELD']} /* SolunumAI.xcdatamodeld */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodel; path = SolunumAI.xcdatamodeld; sourceTree = "<group>"; }};
\t\t{G['REF_APP']} /* SolunumAIApp.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = SolunumAIApp.swift; sourceTree = "<group>"; }};
\t\t{G['REF_HOMEVIEW']} /* HomeView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = HomeView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_ANALYSISVIEW']} /* AnalysisView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AnalysisView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_HISTORYVIEW']} /* HistoryView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = HistoryView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_EXERCISESVIEW']} /* ExercisesView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = ExercisesView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_RISKGAUGE']} /* RiskGaugeView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = RiskGaugeView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_AUDIOWAVEFORM']} /* AudioWaveformView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AudioWaveformView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_BREATHINGANIM']} /* BreathingAnimationView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = BreathingAnimationView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_HEALTHTIPCARD']} /* HealthTipCardView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = HealthTipCardView.swift; sourceTree = "<group>"; }};
\t\t{G['REF_ANALYSISRESULT']} /* AnalysisResult.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AnalysisResult.swift; sourceTree = "<group>"; }};
\t\t{G['REF_CDCLASS']} /* AnalysisEntity+CoreDataClass.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = "AnalysisEntity+CoreDataClass.swift"; sourceTree = "<group>"; }};
\t\t{G['REF_CDPROPS']} /* AnalysisEntity+CoreDataProperties.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = "AnalysisEntity+CoreDataProperties.swift"; sourceTree = "<group>"; }};
\t\t{G['REF_APISERVICE']} /* APIService.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = APIService.swift; sourceTree = "<group>"; }};
\t\t{G['REF_AUDIORECORDER']} /* AudioRecorderService.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AudioRecorderService.swift; sourceTree = "<group>"; }};
\t\t{G['REF_COREDATA_SVC']} /* CoreDataService.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = CoreDataService.swift; sourceTree = "<group>"; }};
\t\t{G['REF_AVFOUNDATION']} /* AVFoundation.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = AVFoundation.framework; path = "Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/AVFoundation.framework"; sourceTree = DEVELOPER_DIR; }};
\t\t{G['REF_COREDATA_FW']} /* CoreData.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = CoreData.framework; path = "Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/CoreData.framework"; sourceTree = DEVELOPER_DIR; }};
\t\t{G['REF_CHARTS_FW']} /* Charts.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = Charts.framework; path = "Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Charts.framework"; sourceTree = DEVELOPER_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{G['FRAMEWORKS_PHASE']} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{G['BF_AVFOUNDATION']} /* AVFoundation.framework in Frameworks */,
\t\t\t\t{G['BF_COREDATA_FW']} /* CoreData.framework in Frameworks */,
\t\t\t\t{G['BF_CHARTS_FW']} /* Charts.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{G['MAIN_GROUP']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['APP_GROUP']} /* App */,
\t\t\t\t{G['VIEWS_GROUP']} /* Views */,
\t\t\t\t{G['COMPONENTS_GROUP']} /* Components */,
\t\t\t\t{G['MODELS_GROUP']} /* Models */,
\t\t\t\t{G['SERVICES_GROUP']} /* Services */,
\t\t\t\t{G['RESOURCES_GROUP']} /* Resources */,
\t\t\t\t{G['PRODUCTS_GROUP']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['PRODUCTS_GROUP']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_PRODUCT']} /* SolunumAI.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['APP_GROUP']} /* App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_APP']} /* SolunumAIApp.swift */,
\t\t\t);
\t\t\tpath = "SolunumAI/App";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['VIEWS_GROUP']} /* Views */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_HOMEVIEW']} /* HomeView.swift */,
\t\t\t\t{G['REF_ANALYSISVIEW']} /* AnalysisView.swift */,
\t\t\t\t{G['REF_HISTORYVIEW']} /* HistoryView.swift */,
\t\t\t\t{G['REF_EXERCISESVIEW']} /* ExercisesView.swift */,
\t\t\t);
\t\t\tpath = "SolunumAI/Views";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['COMPONENTS_GROUP']} /* Components */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_RISKGAUGE']} /* RiskGaugeView.swift */,
\t\t\t\t{G['REF_AUDIOWAVEFORM']} /* AudioWaveformView.swift */,
\t\t\t\t{G['REF_BREATHINGANIM']} /* BreathingAnimationView.swift */,
\t\t\t\t{G['REF_HEALTHTIPCARD']} /* HealthTipCardView.swift */,
\t\t\t);
\t\t\tpath = "SolunumAI/Components";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['MODELS_GROUP']} /* Models */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_ANALYSISRESULT']} /* AnalysisResult.swift */,
\t\t\t\t{G['REF_CDCLASS']} /* AnalysisEntity+CoreDataClass.swift */,
\t\t\t\t{G['REF_CDPROPS']} /* AnalysisEntity+CoreDataProperties.swift */,
\t\t\t\t{G['REF_XCDATAMODELD']} /* SolunumAI.xcdatamodeld */,
\t\t\t);
\t\t\tpath = "SolunumAI/Models";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['SERVICES_GROUP']} /* Services */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_APISERVICE']} /* APIService.swift */,
\t\t\t\t{G['REF_AUDIORECORDER']} /* AudioRecorderService.swift */,
\t\t\t\t{G['REF_COREDATA_SVC']} /* CoreDataService.swift */,
\t\t\t);
\t\t\tpath = "SolunumAI/Services";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{G['RESOURCES_GROUP']} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{G['REF_ASSETS']} /* Assets.xcassets */,
\t\t\t\t{G['REF_INFOPLIST']} /* Info.plist */,
\t\t\t);
\t\t\tpath = "SolunumAI/Resources";
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{G['TARGET']} /* SolunumAI */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {G['TARGET_CFGLIST']} /* Build configuration list for PBXNativeTarget "SolunumAI" */;
\t\t\tbuildPhases = (
\t\t\t\t{G['SOURCES_PHASE']} /* Sources */,
\t\t\t\t{G['FRAMEWORKS_PHASE']} /* Frameworks */,
\t\t\t\t{G['RESOURCES_PHASE']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = SolunumAI;
\t\t\tproductName = SolunumAI;
\t\t\tproductReference = {G['REF_PRODUCT']} /* SolunumAI.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{G['PROJECT']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{G['TARGET']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {G['PROJECT_CFGLIST']} /* Build configuration list for PBXProject "SolunumAI" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = tr;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, tr, Base);
\t\t\tmainGroup = {G['MAIN_GROUP']};
\t\t\tproductRefGroup = {G['PRODUCTS_GROUP']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({G['TARGET']} /* SolunumAI */);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{G['RESOURCES_PHASE']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{G['BF_ASSETS']} /* Assets.xcassets in Resources */,
\t\t\t\t{G['BF_XCDATAMODELD']} /* SolunumAI.xcdatamodeld in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{G['SOURCES_PHASE']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{G['BF_APP']} /* SolunumAIApp.swift in Sources */,
\t\t\t\t{G['BF_HOMEVIEW']} /* HomeView.swift in Sources */,
\t\t\t\t{G['BF_ANALYSISVIEW']} /* AnalysisView.swift in Sources */,
\t\t\t\t{G['BF_HISTORYVIEW']} /* HistoryView.swift in Sources */,
\t\t\t\t{G['BF_EXERCISESVIEW']} /* ExercisesView.swift in Sources */,
\t\t\t\t{G['BF_RISKGAUGE']} /* RiskGaugeView.swift in Sources */,
\t\t\t\t{G['BF_AUDIOWAVEFORM']} /* AudioWaveformView.swift in Sources */,
\t\t\t\t{G['BF_BREATHINGANIM']} /* BreathingAnimationView.swift in Sources */,
\t\t\t\t{G['BF_HEALTHTIPCARD']} /* HealthTipCardView.swift in Sources */,
\t\t\t\t{G['BF_ANALYSISRESULT']} /* AnalysisResult.swift in Sources */,
\t\t\t\t{G['BF_CDCLASS']} /* AnalysisEntity+CoreDataClass.swift in Sources */,
\t\t\t\t{G['BF_CDPROPS']} /* AnalysisEntity+CoreDataProperties.swift in Sources */,
\t\t\t\t{G['BF_APISERVICE']} /* APIService.swift in Sources */,
\t\t\t\t{G['BF_AUDIORECORDER']} /* AudioRecorderService.swift in Sources */,
\t\t\t\t{G['BF_COREDATA_SVC']} /* CoreDataService.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{G['TARGET_DEBUG_CFG']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASETC_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "SolunumAI/Resources/Info.plist";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLE_SWIFT_VERSION = 5.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tOTHER_LDFLAGS = ("-framework AVFoundation", "-framework CoreData");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.solunumai.app";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{G['TARGET_RELEASE_CFG']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASETC_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "SolunumAI/Resources/Info.plist";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLE_SWIFT_VERSION = 5.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tOTHER_LDFLAGS = ("-framework AVFoundation", "-framework CoreData");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.solunumai.app";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{G['PROJECT_DEBUG_CFG']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{G['PROJECT_RELEASE_CFG']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{G['PROJECT_CFGLIST']} /* Build configuration list for PBXProject "SolunumAI" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{G['PROJECT_DEBUG_CFG']} /* Debug */,
\t\t\t\t{G['PROJECT_RELEASE_CFG']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{G['TARGET_CFGLIST']} /* Build configuration list for PBXNativeTarget "SolunumAI" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{G['TARGET_DEBUG_CFG']} /* Debug */,
\t\t\t\t{G['TARGET_RELEASE_CFG']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {G['PROJECT']} /* Project object */;
}}
"""

# ── workspace file ────────────────────────────────────────────────────────────

workspace_data = """\
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

# ── main ──────────────────────────────────────────────────────────────────────

def main():
    proj_dir = ROOT / "SolunumAI.xcodeproj"
    ws_dir   = proj_dir / "project.xcworkspace"

    proj_dir.mkdir(exist_ok=True)
    ws_dir.mkdir(exist_ok=True)

    pbxproj_path = proj_dir / "project.pbxproj"
    pbxproj_path.write_text(pbxproj(), encoding="utf-8")

    ws_path = ws_dir / "contents.xcworkspacedata"
    ws_path.write_text(workspace_data, encoding="utf-8")

    print("✅  SolunumAI.xcodeproj oluşturuldu!")
    print()
    print("📱 Açmak için:")
    print("   open SolunumAI.xcodeproj")
    print()
    print("ℹ️  Xcode'da:")
    print("   1. Signing & Capabilities → Team seçin")
    print("   2. Simulator veya gerçek cihaz seçin")
    print("   3. ▶ ile çalıştırın")

if __name__ == "__main__":
    main()
