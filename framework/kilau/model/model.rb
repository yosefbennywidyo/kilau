module Kilau
  # Persistence for a generated entity. The model class supplies
  # validate(errors); the entity supplies its SQL, binds and touch.
  module Model
    def errors
      @errors ||= Errors.new
    end

    def validate(errors)
      nil
    end

    def valid?
      errors.clear
      validate(errors)
      errors.empty?
    end

    def save(db)
      return false unless valid?
      touch(Time.now.to_i)
      if id.nil?
        self.id = db.insert(insert_sql, insert_binds)
      else
        db.execute(update_sql, update_binds)
      end
      true
    end

    def destroy(db)
      return false if id.nil?
      db.execute(delete_sql, Kilau::DB::Binds.new.int(id)) == 1
    end
  end
end
