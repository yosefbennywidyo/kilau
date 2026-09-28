require "kilau"
require_relative "../kilau_tool/entities_gen"
T = Kilau::Testing

def column(name, type, not_null, primary_key)
  KilauTool::EntitiesGen::Column.new(name, type, not_null, primary_key)
end

widgets = [
  column("id", "INTEGER", false, true),
  column("name", "TEXT", true, false),
  column("note", "TEXT", false, false),
  column("created_at", "INTEGER", true, false),
  column("updated_at", "INTEGER", true, false),
]
print KilauTool::EntitiesGen.render("widgets", widgets)

T.check("class_name singularizes posts") { KilauTool::EntitiesGen.class_name("posts") == "Post" }
T.check("class_name turns ies into y") { KilauTool::EntitiesGen.class_name("categories") == "Category" }
T.check("class_name camelizes snake case") { KilauTool::EntitiesGen.class_name("blog_posts") == "BlogPost" }

unsupported = begin
  KilauTool::EntitiesGen.render("files", [column("id", "INTEGER", false, true), column("data", "BLOB", true, false)])
  false
rescue ArgumentError
  true
end
T.check("an unsupported column type raises") { unsupported }

no_id = begin
  KilauTool::EntitiesGen.render("tags", [column("label", "TEXT", true, false)])
  false
rescue ArgumentError
  true
end
T.check("a table without an id primary key raises") { no_id }

tags = KilauTool::EntitiesGen.render("tags", [column("id", "INTEGER", false, true), column("label", "TEXT", true, false)])
T.check("a table without timestamps renders an empty touch") { tags.include?("    def touch(now)\n    end\n") }
