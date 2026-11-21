class M20260929000002Users < Kilau::Migration
  def version = "20260929000002"

  def up(schema)
    schema.create_table("users") do |t|
      t.pk_auto("id")
      t.string("email")
      t.string("password_digest")
      t.timestamps
    end
    schema.add_unique_index("users", "email")
  end

  def down(schema) = schema.drop_table("users")
end
