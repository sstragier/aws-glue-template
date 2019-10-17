# Environment Setup
The following describes what the `bin/install-spark.ps1` script is doing

## Installing Maven
Maven is used to install AWS Glue's Java dependencies. This are required to run AWS Glue jobs locally.

1. Download [Maven](https://maven.apache.org/download.cgi)
1. Unzip Maven to the desired folder
1. Add Maven's `bin` folder to the `PATH` environment variable

## Installing Spark
Spark is used to run the AWS Glue job

1. Download [Spark 2.4.3 with Hadoop 2.8](https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-1.0/spark-2.4.3-bin-hadoop2.8.tgz)
1. Unzip Spark to the desired folder
    * The folder path cannot contain spaces
    * 7Zip can be used to to open the tgz file
1. Create a `SPARK_HOME` environment variable that points to the Spark folder

## Installing Hadoop's winutils (Windows Only)
In order for Spark to correctly run in standalone mode without Hadoop, the Hadoop winutils binaries need to be downloaded and installed.

1. Create a folder for Hadoop
    * The folder path cannot contain spaces
1. Create a `HADOOP_HOME` environment variable that points to the Hadoop folder
1. Add a `bin` folder to `HADOOP_HOME`
1. Add `%HADOOP_HOME/bin` to the `PATH` environment variable
1. Go to this [Github repo](https://github.com/steveloughran/winutils) and download `hadoop.dll` and `winutils.exe` from the bin folder for your Hadoop version
1. Move `hadoop.dll` and `winutils.exe` to `HADOOP_HOME/bin`