Feature:
  Testing the people tab.

  @api
  Scenario: Test the People tab
    Given I visit "john"
     When I click "People"
      And I click "John Fitzgerald Kennedy"
     Then I should see "often referred to by his initials JFK"

  @api
  Scenario: Testing the autocomplete field or profile syncing.
    Given I am logging in as "john"
      And I visit "john/cp/people/sync-profiles"
      And I fill in "autocomplete" with "Hillary Diane Rodham Clinton (58)"
      And I press "Submit"
      And I should see "The person Hillary Diane Rodham Clinton has created. You can visit their page."
     When I click "visit"
     Then I should see "Hillary Diane Rodham Clinton"
      And I should see "67th United States Secretary of State"
    # Verify the user is in john's vsite and the source node vsite.
      And I should see "John"

  @api
  Scenario: When syncing the same node we need to check we updated the copied
            node and create a new one.
    Given I am logging in as "john"
      And I update the node "Hillary Diane Rodham Clinton" field "Address" to "White house"
      And I visit "john/cp/people/sync-profiles"
      And I fill in "autocomplete" with "Hillary Diane Rodham Clinton (58)"
      And I press "Submit"
      And I should see "The person Hillary Diane Rodham Clinton has updated. You can visit their page."
     When I click "visit"
     Then I should see "Hillary Diane Rodham Clinton"
      And I should see "67th United States Secretary of State"
    # Verify the user is in john's vsite and the source node vsite.
      And I should see "John"
      And I should see "White house"

  @api
  Scenario: Empty the value of a field from the original node and check the
            listener node updated.
    Given I am logging in as "john"
      And I visit "obama/node/58/edit"
     When I fill in "Address" with ""
      And I press "Save"
      And I sleep for "10"
      And I visit "john/people/hillary-diane-rodham-clinton"
     Then I should not see "White house"
