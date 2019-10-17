# Tips and Troubleshooting

- [Debugging third-party libraries](#Debugging-third-party-libraries)
    - [Limitations](#limitations)
- [Inspecting Java Objects](#inspecting-java-objects)
- [Passing connection parameters to a database connection](Passing-connection-parameters-to-a-database-connection)
- [Using a Glue database connection that enforces SSL](#Using-a-Glue-database-connection-that-enforces-SSL)

## Debugging third-party libraries
VS Code can step into third-party libraries if they are installed to the default python module folder by using pip. For other libraries, such as pyspark, VS Code can load these libraries by adding the path to the `python.autoComplete.extraPaths` setting.
```javascript
{
    // Tell the compiler about the Spark libraries
    "python.autoComplete.extraPaths": [ "${env:SPARK_HOME}/python" ]
}
```

### Limitations
Currently VS Code does not support stepping into zip files, so if a library is zipped, it won't be able to open the python file.

This can cause confusion when an exception is thrown because VS Code will break on the exception but won't be able to open the file. It will display a notification that the file couldn't be opened and the call stack will show that the debugger is currently paused on an exception. The debug commands (continue, step out, etc) still work, but you can't see what line of code the debugger is on until exiting the zip file back to unzipped python files.

## Inspecting Java Objects
Spark and Glue use [py4j](https://py4j.org/) to interoperate with Java libraries. When debugging and inspecting an object is described by the inspector as a `JavaObject` this is a py4j proxy.

- Methods, including getters and setters, can be invoked as normal.
    ```python
    javaObject.toString()
    javaObject.getClass()
    javaObject.setField(value)
    ```
- Fields will be visible via the inspector as `JavaMembers`, but they can only be accessed via the `java_gateway`'s `get_field` and `set_field` methods.
    ```python
    from py4j.java_gateway import get_field, set_field

    get_field(javaObject, "fieldName")
    set_field(javaObject, "fieldName", value)
    ```
- Private members can be accessed using Java reflection
- If a non-existent member is accessed on a py4j proxy, py4j will return a `JavaMember` for that member and it will show up in the inspector even though it doesn't exist in the underlying Java class. Trying to call the member as a method or access it as a field (with `get/set_field`) will fail.

For additional information about typical uses for py4j, see py4j's [FAQs](https://www.py4j.org/faq.html).

## Passing connection parameters to a database connection
Connection parameters can be provided to a database connection when calling `GlueContext.create_dynamic_frame_from_catalog` with `additional_options` which is a dictionary where the keys of the dictionary are the name of the connection parameter.

For example, the below sample shows passing the `enforceSSL` and `ssl` connection parameters. These will be applied to the JDBC connection.

```python
datasource = glueContext.create_dynamic_frame_from_catalog(
    database=glueDatabaseName,
    table_name=glueTableName,
    additional_options = {
        # Connection parameters can go here, e.g.:
        "enforceSSL": False,
        "ssl": True
    }
)
```

## Using a Glue database connection that enforces SSL
When a Glue database connection using Amazon RDS is used that enforces SSL, it will not run locally because there appears to be a bug with loading the root CA certificate. Specifying the connection parameters to set the root CA certificate or to use SSL Mode require instead of verify-all also does not work.

This will normally result in an exception when trying to connect to the database, such as: `"Could not open SSL root certificate file ."`. It is normal to see this exception logged when the below workaround is applied because when not enforcing SSL, Glue still tries to connect using SSL first, which fails, and then it falls back to a non-SSL connection.

A workaround is to turn off SSL enforcement by setting the following connection parameters:
- `enforceSSL` = false

```python
# launch.config or glue-spark-submit can pass in a --LOCAL argument
isLocal = "--LOCAL" in sys.argv

# Only disable enforcing SSL when running locally so the cloud still enforces SSL
connectionParameters = {}
if isLocal:
    additionalOptions["enforceSSL"] = False

datasource = glueContext.create_dynamic_frame_from_catalog(
    # ...
    additional_options = connectionParameters
)
```