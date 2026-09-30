require "kilau"
include Kilau::Testing

# The helpers read bare after a top-level include (K-004), beside the
# module form the other tests use.
check("a bare check passes") { 1 + 1 == 2 }
check("a bare check sees no db error") { !raises_db_error? { :fine } }
# A bare raises_db_error? whose block always raises needs spinel >= c6cff7c76
# (K-021, matz/spinel#6151); older ones fail to compile it.
check("a bare check sees a db error") { raises_db_error? { raise Sqlite::Error, "boom" } }
Kilau::Testing.check("the module form still works") { true }
