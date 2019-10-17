REM Use this to run pytest. Arguments to this batch file will be passed to the Spark executable.
REM E.g. ./bin/glue-pytest.cmd ./test-mod.py

@ECHO OFF

call %~dp0/glue-setup.cmd

echo Running: pytest %*
call pytest %*