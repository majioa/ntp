Feature: As a end-to-end tester, I want a NTP server that will adjust servers-under-test's time so those servers will process based on schedule.

@server.S1
Scenario: Server runs on demand
  Given I have an NTP service that is running on localhost
  When I request the time from it
  Then the time is near to now

@server.S2
Scenario: Server can change time
  Given I have an NTP service that is running on localhost
  When I change the time to '2016/01/01T12:00:01'
  And I request the time from it
  Then the time is near to '2016/01/01T12:00:01'

@server.S3
Scenario: Server can reset to current time
  Given I have an NTP service that is running on localhost
  When I change the time to '2016/01/01T12:00:01'
  And I reset it
  And I request the time from it
  Then the time is near to now
