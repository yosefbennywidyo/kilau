require_relative "_entities/users"

class User < Entities::User
  include Kilau::Model

  MIN_PASSWORD_LENGTH = 8
  MAX_EMAIL_LENGTH = 254

  def self.normalize_email(raw) = raw.strip.downcase

  # Deliberately loose: one "@" with something on each side, no whitespace.
  # Whether the address really exists is settled by mailing it, not by a regexp.
  def self.valid_email?(email)
    return false if email.empty? || email.length > MAX_EMAIL_LENGTH
    return false if email.match?(/\s/)
    parts = email.split("@", -1)
    parts.size == 2 && !parts[0].empty? && !parts[1].empty?
  end

  def self.find_by_id(db, id) = db.query_first(select_sql + " WHERE id = ? LIMIT 1", Sqlite::Binds.new.int(id)) { |row| from_row(row) }
  def self.find_by_email(db, email) = db.query_first(select_sql + " WHERE email = ? LIMIT 1", Sqlite::Binds.new.text(email)) { |row| from_row(row) }

  # [the new user, []] or [nil, messages]. Every check runs before the
  # expensive hash, and the length check before anything touches a huge
  # password. A duplicate email is an ordinary validation error, whether the
  # lookup finds it or the UNIQUE index refuses the insert of a request that
  # raced this one.
  def self.register(db, email, password)
    address = normalize_email(email)
    errors = []
    errors << "email tidak valid" unless valid_email?(address)
    if password.bytesize > Kilau::Password::MAX_BYTES
      errors << "sandi terlalu panjang"
    elsif password.length < MIN_PASSWORD_LENGTH
      errors << "sandi minimal 8 karakter"
    end
    errors << "email sudah terdaftar" if errors.empty? && !find_by_email(db, address).nil?
    return [nil, errors] unless errors.empty?
    user = create(db, address, Kilau::Password.digest(password))
    return [user, errors] unless user.nil?
    errors << "email sudah terdaftar"
    [nil, errors]
  end

  # nil when the UNIQUE index on email refuses the row. Any other database
  # error is not a duplicate and propagates.
  def self.create(db, address, digest)
    user = new
    user.email = address
    user.password_digest = digest
    begin
      user.save(db)
    rescue Sqlite::Error => e
      raise e if find_by_email(db, address).nil?
      return nil
    end
    user
  end

  def authenticate?(password) = Kilau::Password.verify?(password, password_digest)
end
