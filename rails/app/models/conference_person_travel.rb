class Conference_person_travel < Momomoto::Table

  def self.log_content_columns
    columns.keys - [:conference_person_id]
  end

  def self.log_change_url( change )
    cp = Conference_person.select_single({:conference_person_id=>change.conference_person_id})
    {:controller=>'person',:action=>:edit,:person_id=>cp.person_id}
   rescue
    {}
  end

  def self.log_change_title( change )
    Conference_person.log_change_title( Conference_person.select_single({:conference_person_id=>change.conference_person_id}) )
   rescue
    ""
  end

end

