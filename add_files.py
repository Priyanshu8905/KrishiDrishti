# add_files.py
# Python script to programmatically add KrishiDrishti enterprise files to Xcode project structure

import os

project_path = "/Users/kaushikirai/Desktop/KrishiDrishti/KrishiDrishti_fixed 3/KrishiDrishti.xcodeproj/project.pbxproj"

new_files = [
    ("KrishiDrishti/Core/DI/DIContainer.swift", "DIContainer.swift"),
    ("KrishiDrishti/Core/Security/KeychainManager.swift", "KeychainManager.swift"),
    ("KrishiDrishti/Core/Security/SecurityManager.swift", "SecurityManager.swift"),
    ("KrishiDrishti/Core/Network/Endpoint.swift", "Endpoint.swift"),
    ("KrishiDrishti/Core/Network/APIClient.swift", "APIClient.swift"),
    ("KrishiDrishti/Core/Network/NetworkManager.swift", "NetworkManager.swift"),
    ("KrishiDrishti/Services/AI/CoreMLService.swift", "CoreMLService.swift"),
    ("KrishiDrishti/Services/AI/VisionService.swift", "VisionService.swift"),
    ("KrishiDrishti/Services/AI/PredictionEngine.swift", "PredictionEngine.swift"),
    ("KrishiDrishti/Services/AR/ARSessionManager.swift", "ARSessionManager.swift"),
    ("KrishiDrishti/Services/AR/ARViewContainer.swift", "ARViewContainer.swift"),
    ("KrishiDrishti/Services/Notification/NotificationManager.swift", "NotificationManager.swift"),
    ("KrishiDrishti/Services/Location/LocationManager.swift", "LocationManager.swift"),
    ("KrishiDrishti/Services/Location/MapService.swift", "MapService.swift"),
    ("KrishiDrishti/Services/Motion/MotionManager.swift", "MotionManager.swift"),
    ("KrishiDrishti/Services/Purchase/StoreManager.swift", "StoreManager.swift"),
    ("KrishiDrishti/Services/Purchase/PurchaseManager.swift", "PurchaseManager.swift"),
    ("KrishiDrishti/Managers/PersistenceController.swift", "PersistenceController.swift"),
    ("KrishiDrishti/Managers/DataManager.swift", "DataManager.swift"),
    ("KrishiDrishti/Repositories/WeatherRepository.swift", "WeatherRepository.swift"),
    ("KrishiDrishti/Repositories/CropProblemRepository.swift", "CropProblemRepository.swift"),
    ("KrishiDrishti/Repositories/UserProfileRepository.swift", "UserProfileRepository.swift"),
    ("KrishiDrishti/Views/AR/ARMappingView.swift", "ARMappingView.swift"),
    ("KrishiDrishti/Views/Purchase/SubscriptionView.swift", "SubscriptionView.swift"),
    ("KrishiDrishti/Views/Scanner/CropVisualization3DView.swift", "CropVisualization3DView.swift")
]

with open(project_path, 'r') as file:
    content = file.read()

build_files = []
file_refs = []
build_phase_entries = []
group_entries = []

for idx, (path, filename) in enumerate(new_files):
    fref_id = f"FNEW{idx:04d}"
    bfile_id = f"ANEW{idx:04d}"
    
    # 1. PBXBuildFile Section Entry
    build_files.append(f"\t\t{bfile_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref_id} /* {filename} */; }};")
    
    # 2. PBXFileReference Section Entry
    file_refs.append(f"\t\t{fref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};")
    
    # 3. Sources Build Phase Entry
    build_phase_entries.append(f"\t\t\t\t{bfile_id} /* {filename} in Sources */,")
    
    # 4. GAPP Group Entry
    group_entries.append(f"\t\t\t\t{fref_id} /* {filename} */,")

# Insert Build Files
build_file_marker = "/* Begin PBXBuildFile section */"
if build_file_marker in content:
    parts = content.split(build_file_marker)
    inserted_build = "\n".join(build_files)
    content = parts[0] + build_file_marker + "\n" + inserted_build + parts[1]

# Insert File References
file_ref_marker = "/* Begin PBXFileReference section */"
if file_ref_marker in content:
    parts = content.split(file_ref_marker)
    inserted_refs = "\n".join(file_refs)
    content = parts[0] + file_ref_marker + "\n" + inserted_refs + parts[1]

# Insert into PBXSourcesBuildPhase
sources_phase_marker = "BPSOURCES /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ("
if sources_phase_marker in content:
    parts = content.split(sources_phase_marker)
    inserted_entries = "\n" + "\n".join(build_phase_entries)
    content = parts[0] + sources_phase_marker + inserted_entries + parts[1]

# Insert into GAPP group
gapp_marker = "GAPP /* KrishiDrishti */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ("
if gapp_marker in content:
    parts = content.split(gapp_marker)
    inserted_group = "\n" + "\n".join(group_entries)
    content = parts[0] + gapp_marker + inserted_group + parts[1]

with open(project_path, 'w') as file:
    file.write(content)

print("Successfully injected all new files into the Xcode project file.")
