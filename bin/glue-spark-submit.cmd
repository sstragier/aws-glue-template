REM Use this to submit spark jobs to Spark (via Spark's spark-submit.cmd). Arguments to this batch file will be passed
REM to the Spark executable.
REM E.g. ./bin/glue-spark-submit.cmd ./sample-job.py --JOB_NAME=LocalJob

@ECHO OFF

call %~dp0/glue-setup.cmd

echo Running: %SPARK_HOME%/bin/spark-submit.cmd %*
call %SPARK_HOME%/bin/spark-submit.cmd %*