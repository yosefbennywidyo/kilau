class M20260928000001Posts < Kilau::Migration
  def version = "20260928000001"

  def up(schema)
    schema.create_table("posts") do |t|
      t.pk_auto("id")
      t.string("title")
      t.text("content")
      t.timestamps
    end
  end

  def down(schema) = schema.drop_table("posts")
end
