# Kilau's posts table stores created_at/updated_at as INTEGER epoch
# seconds; Rails' timestamping casts Time to Integer for those columns.
class Post < ApplicationRecord
  validate do
    errors.add(:title, "minimal 2 karakter") if title.to_s.length < 2
    errors.add(:content, "wajib diisi") if content.to_s.empty?
  end
end
