
CREATE TABLE base.event_role_localized (
  event_role TEXT NOT NULL,
  translated TEXT NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE event_role_localized (
  FOREIGN KEY (event_role) REFERENCES event_role (event_role) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (translated) REFERENCES language (language) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (event_role, translated)
) INHERITS( base.event_role_localized );

CREATE TABLE log.event_role_localized (
) INHERITS( base.logging, base.event_role_localized );

CREATE INDEX log_event_role_localized_event_role_idx ON log.event_role_localized( event_role );
CREATE INDEX log_event_role_localized_log_transaction_id_idx ON log.event_role_localized( log_transaction_id );

