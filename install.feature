Feature: Install
  In order to testg pointzi
  Testers
  want to Create an install 

  Scenario: Web Page1
    When I make a GET request to "/v3/debug".
    Then the response status must be "200".
    Then the json at path "$.status" must be "ok".
    
  Scenario: Set server name, headers and reset test user's database
    When I make a CSRF form POST request to "/accounts/login" with data
    """
    {
        "login": "behave@streethawk.com",
        "password": "password"
    }
    """
    Then the json at path "$.status" must be "ok".
