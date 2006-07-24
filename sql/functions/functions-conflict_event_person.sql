
-- returns all conclicts related to events
CREATE OR REPLACE FUNCTION conflict_event_person(integer) RETURNS SETOF conflict_event_person_conflict AS '
  DECLARE
    cur_conference_id ALIAS FOR $1;
    cur_conflict_event_person RECORD;
    cur_conflict RECORD;

  BEGIN

    FOR cur_conflict IN
      SELECT conflict.conflict_id, 
             conflict.conflict_type_id, 
             conflict.tag 
        FROM conflict 
             INNER JOIN conflict_type USING (conflict_type_id)
             INNER JOIN conference_phase_conflict USING (conflict_id)
             INNER JOIN conference USING (conference_phase_id)
             INNER JOIN conflict_level USING (conflict_level_id)
       WHERE conflict_type.tag = ''event_person'' AND
             conflict_level.tag <> ''silent'' AND
             conference.conference_id = cur_conference_id
    LOOP
      FOR cur_conflict_event_person IN
        EXECUTE ''SELECT conflict_id, event_id, person_id FROM conflict_'' || cur_conflict.tag || ''('' || cur_conference_id || ''), ( SELECT '' || cur_conflict.conflict_id || '' AS conflict_id) AS conflict_id; ''
      LOOP
        RETURN NEXT cur_conflict_event_person;
      END LOOP;
    END LOOP;

    RETURN;
  END;
' LANGUAGE 'plpgsql' RETURNS NULL ON NULL INPUT;

-- returns event_persons that do not speak the language of the event
CREATE OR REPLACE FUNCTION conflict_event_person_language(integer) RETURNS SETOF conflict_event_person AS '
  DECLARE
    cur_conference_id ALIAS FOR $1;
    cur_event RECORD;
    cur_speaker RECORD;
    cur_conflict conflict_event_person%rowtype;
  BEGIN

-- Loop through all event_persons
    FOR cur_speaker IN
      SELECT event_id, person_id, language_id 
        FROM event_person
        INNER JOIN event_role USING (event_role_id)
        INNER JOIN event_role_state USING (event_role_state_id)
        INNER JOIN event USING (event_id)
        INNER JOIN event_state USING (event_state_id)
        WHERE event_role.tag IN (''speaker'', ''moderator'') AND
              event_role_state.tag = ''confirmed'' AND
              event.conference_id = cur_conference_id AND
              event.language_id IS NOT NULL
    LOOP
      IF NOT EXISTS (SELECT 1 FROM person_language WHERE person_id = cur_speaker.person_id AND language_id = cur_speaker.language_id )
      THEN
        cur_conflict.person_id := cur_speaker.person_id;
        cur_conflict.event_id := cur_speaker.event_id;
        RETURN NEXT cur_conflict;
      END IF;
    END LOOP;
    RETURN;
  END;
' LANGUAGE 'plpgsql' RETURNS NULL ON NULL INPUT;

-- returns all events starting before the arrival of the speaker
CREATE OR REPLACE FUNCTION conflict_event_person_event_before_arrival(integer) RETURNS SETOF conflict_event_person AS '
  DECLARE
    cur_conference_id ALIAS FOR $1;
    cur_conflict conflict_event_person%rowtype;
  BEGIN

    FOR cur_conflict IN
      SELECT event_id, person_id
        FROM event_person
        INNER JOIN event USING (event_id)
        INNER JOIN person_travel USING (person_id, conference_id)
        INNER JOIN event_state ON (
            event.event_state_id = event_state.event_state_id AND
            event_state.tag = ''accepted''
        )
        INNER JOIN conference ON (
            event.conference_id = conference.conference_id AND
            conference.conference_id = cur_conference_id
        )
        INNER JOIN event_role ON (
            event_role.event_role_id = event_person.event_role_id AND
            event_role.tag IN (''speaker'', ''moderator'')
        )
        INNER JOIN event_role_state ON (
            event_role_state.event_role_state_id = event_person.event_role_state_id AND
            event_role_state.tag = ''confirmed''
        )
      WHERE (
          person_travel.arrival_date IS NOT NULL AND
          person_travel.arrival_time IS NULL AND
          person_travel.arrival_date > conference.start_date + event.day + ''-1''::integer
        ) OR (
          person_travel.arrival_date IS NOT NULL AND
          person_travel.arrival_time IS NOT NULL AND
          (person_travel.arrival_date + person_travel.arrival_time)::timestamp > (conference.start_date + event.day + ''-1''::integer + event.start_time + conference.day_change)::timestamp
        )
    LOOP
      RETURN NEXT cur_conflict;
    END LOOP;
    RETURN;
  END;
' LANGUAGE 'plpgsql' RETURNS NULL ON NULL INPUT;

-- returns all events starting before the arrival of the speaker
CREATE OR REPLACE FUNCTION conflict_event_person_event_after_departure(integer) RETURNS SETOF conflict_event_person AS '
  DECLARE
    cur_conference_id ALIAS FOR $1;
    cur_conflict conflict_event_person%rowtype;
  BEGIN

    FOR cur_conflict IN
      SELECT event_id, person_id
        FROM event_person
        INNER JOIN event USING (event_id)
        INNER JOIN person_travel USING (person_id, conference_id)
        INNER JOIN event_state ON (
            event.event_state_id = event_state.event_state_id AND
            event_state.tag = ''accepted''
        )
        INNER JOIN conference ON (
            event.conference_id = conference.conference_id AND
            conference.conference_id = cur_conference_id
        )
        INNER JOIN event_role ON (
            event_role.event_role_id = event_person.event_role_id AND
            event_role.tag IN (''speaker'', ''moderator'')
        )
        INNER JOIN event_role_state ON (
            event_role_state.event_role_state_id = event_person.event_role_state_id AND
            event_role_state.tag = ''confirmed''
        )
      WHERE (
          person_travel.departure_date IS NOT NULL AND
          person_travel.departure_time IS NULL AND
          person_travel.departure_date < conference.start_date + event.day + ''-1''::integer
        ) OR (
          person_travel.departure_date IS NOT NULL AND
          person_travel.departure_time IS NOT NULL AND
          (person_travel.departure_date + person_travel.departure_time)::timestamp < (conference.start_date + event.day + ''-1''::integer + event.start_time + conference.day_change + event.duration)::timestamp
        )
    LOOP
      RETURN NEXT cur_conflict;
    END LOOP;
    RETURN;
  END;
' LANGUAGE 'plpgsql' RETURNS NULL ON NULL INPUT;

