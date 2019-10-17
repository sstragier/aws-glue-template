@ECHO OFF

ECHO.
ECHO Setting up Glue environment variables

SET PROJECT_PATH=%~dp0/..

REM Add the project path to the python path so that the awsglue module can be found
SET PYTHONPATH=%PYTHONPATH%;%PROJECT_PATH%
ECHO PYTHONPATH=%PYTHONPATH%

REM Spark uses SPARK_CONF_DIR to load additional config files. This tells Spark about the /conf/spark-defaults.conf
REM which points to the /jars folder
SET SPARK_CONF_DIR=%PROJECT_PATH%/conf
ECHO SPARK_CONF_DIR=%SPARK_CONF_DIR%

ECHO Done setting up Glue environment variables
ECHO.