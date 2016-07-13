# CocoaPodsGen
Script to generate Cocoapods new lib versions and submit to your Cocoapods Spec repo 

## Setup

To run CPG add the cpg.sh and cpg.yml to your lib project. 

Open the cpg.yml and add to the plist_dir the project internal path to the info.plist file (don't include the file nome, only the directory.)

Run the following command:
 ```chmod u+x cpg.sh```

## Generate a new version

Once you are done with your changes to the new version of the library, commit and push your changes but do not change version on the project, the CocoaPodsGen script will do the job.

Finally run the following command: 
 ```source cpg.sh```