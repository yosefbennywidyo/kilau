require_relative "_entities/posts"

class Post < Entities::Post
  include Kilau::Model

  def validate(errors)
    errors.add("title", "minimal 2 karakter") if title.to_s.length < 2
    errors.add("content", "wajib diisi") if content.to_s.empty?
  end

  def self.all(db) = db.query_all(select_sql + " ORDER BY id DESC", Sqlite::Binds.new) { |row| from_row(row) }
  def self.find_by_id(db, id) = db.query_first(select_sql + " WHERE id = ? LIMIT 1", Sqlite::Binds.new.int(id)) { |row| from_row(row) }
end
