REM Use this to submit launch the pyspark shell (via Spark's pyspark.cmd). Arguments to this batch file will be passed
REM to the Spark executable.
REM E.g. ./bin/glue-pyspark.cmd

@ECHO OFF

call %~dp0/glue-setup.cmd

echo Running: %SPARK_HOME%/bin/pyspark.cmd %*
call %SPARK_HOME%/bin/pyspark.cmd %*