BlogEntry.class_eval do
  metadata(:metadata) do
    boolean :event
    date :event_date
  end
end
