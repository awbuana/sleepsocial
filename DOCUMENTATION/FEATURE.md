## Feature: Sleep Tracking - Clock In/Out
As a user,
I want to be able to clock in (go to bed) and clock out (wake up),
so I can track my sleep times.

**Assumptions**

1. User can clock in anytime, not only in the night
2. User must complete previous clock in first, before making any other clock in
3. User can clock in many times as long as it doesn't overlapped with other clock in
4. Leaderboard doesn't show on-going clock in

### Scenario: Successful Clock In for Going to Bed
```
Given I am a registered user
And I am not currently clocked in
When I initiate a "clock in" operation for going to bed
Then my current timestamp is recorded as a new sleep entry's start time
And the API response includes a list of all my sleep records, ordered by creation time, with the new entry included.
```

### Scenario: Successful Clock Out for Waking Up
```
Given I am a registered user
And I have an active "clock in" entry without a recorded wake-up time
When I initiate a "clock out" operation for waking up
Then my current timestamp is recorded as the end time for my most recent active sleep entry
And the API response includes a list of all my sleep records, ordered by creation time, with the updated entry included.
```

### Scenario: Viewing All My Sleep Records
```
Given I am a registered user
And I have multiple sleep records, some with both start and end times, some with only start times
When I request to view all my sleep records
Then the API returns a list of all my sleep records, ordered by their creation (clock-in) time, from oldest to newest.
```

## Feature: User Following
As a user,
I want to be able to follow and unfollow other users,
so I can track their sleep patterns.

### Scenario: Successfully Following Another User
```
Given I am a registered user
And there is another registered user "User B"
And I am not currently following "User B"
When I send a request to follow "User B"
Then "User B" is added to my list of followed users
And the API confirms that "User B" has been successfully followed.
```

### Scenario: Successfully Unfollowing Another User
```
Given I am a registered user
And I am currently following "User C"
When I send a request to unfollow "User C"
Then "User C" is removed from my list of followed users
And the API confirms that "User C" has been successfully unfollowed.
```

### Scenario: Attempting to Follow an Already Followed User
```
Given I am a registered user
And I am already following "User D"
When I send a request to follow "User D" again
Then my list of followed users remains unchanged
And the API indicates that "User D" is already being followed (or returns a success without duplication).
```

### Scenario: Attempting to Unfollow a User Not Followed
```
Given I am a registered user
And I am not following "User E"
When I send a request to unfollow "User E"
Then my list of followed users remains unchanged
And the API indicates that "User E" was not being followed.
```

## Feature: Viewing Followed Users' Weekly Sleep Records
As a user,
I want to see the sleep records of all users I follow from the previous week, sorted by their sleep duration,
so I can compare sleep habits with my friends.

### Scenario: Viewing Followed Users' Sleep Records from Previous Week
```
Given I am a registered user
And I am following "User F" and "User G"
And "User F" has sleep records within the last 7 days with durations of 7 hours and 8 hours
And "User G" has sleep records within the last 7 days with durations of 6 hours and 9 hours
When I request to view the sleep records of my followed users for the previous week
Then the API returns a consolidated list of "User F" and "User G"'s sleep records from the previous week
And the list is sorted in descending order based on the duration of each individual sleep record (e.g., 9h, 8h, 7h, 6h).
And each record includes details such as the user's name, start time, end time, and calculated duration.
```

### Scenario: No Sleep Records for Followed Users in Previous Week
```
Given I am a registered user
And I am following "User H"
And "User H" has no sleep records within the last 7 days
When I request to view the sleep records of my followed users for the previous week
Then the API returns an empty list or a message indicating no records found for the specified period.
```

### Scenario: Viewing Records When Not Following Any Users
```
Given I am a registered user
And I am not following any other users
When I request to view the sleep records of my followed users for the previous week
Then the API returns an empty list or a message indicating that I am not following anyone.
```

### Scenario: Handling Partial Sleep Records (Clock-in only) in Followed Users' View
```
Given I am a registered user
And I am following "User I"
And "User I" has a sleep record from the previous week that is clocked in but not yet clocked out (ongoing sleep)
When I request to view the sleep records of my followed users for the previous week
Then the API DOESN'T include "User I"'s ongoing sleep record
```
