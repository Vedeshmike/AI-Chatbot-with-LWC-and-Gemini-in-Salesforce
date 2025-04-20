@isTest
public class AIAgentTest {
    
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Create test users
        List<User> testUsers = new List<User>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Title = 'Developer',
            Department = 'IT'
        );
        
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            Title = 'Admin',
            Department = 'Operations'
        );
        
        testUsers.add(testUser1);
        testUsers.add(testUser2);
        
        insert testUsers;
    }
    
    // Mock HTTP response for successful API call
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Mock response body from Gemini API
            String responseBody = '{' +
                '"candidates": [' +
                    '{' +
                        '"content": {' +
                            '"parts": [' +
                                '{' +
                                    '"text": "Here are the active users in the system: John Doe (Developer, IT), Jane Smith (Admin, Operations)."' +
                                '}' +
                            '],' +
                            '"role": "model"' +
                        '},' +
                        '"finishReason": "STOP",' +
                        '"index": 0' +
                    '}' +
                '],' +
                '"promptFeedback": {' +
                    '"safetyRatings": [' +
                        '{' +
                            '"category": "HARM_CATEGORY_HARASSMENT",' +
                            '"probability": "NEGLIGIBLE"' +
                        '}' +
                    ']' +
                '}' +
            '}';
            
            res.setBody(responseBody);
            return res;
        }
    }
    
    // Mock HTTP response for API error
    public class MockHttpErrorResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('{"error": {"message": "Invalid request", "type": "invalid_request_error"}}');
            return res;
        }
    }
    
    // Test method for successful API call
    @isTest
    static void testAskOpenAISuccess() {
        // Set the mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to test
        Test.startTest();
        String result = OpenAIAgent.askOpenAI('List all active users');
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('active users'), 'Response should contain relevant information about users');
    }
    
    // Test method for API error
    @isTest
    static void testAskOpenAIError() {
        // Set the mock callout class for error response
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator());
        
        // Call the method to test
        Test.startTest();
        String result = OpenAIAgent.askOpenAI('List all active users');
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('HTTP Error'), 'Response should contain error information');
    }
    
    // Test for exception handling
    @isTest
    static void testAskOpenAIException() {
        // Set up a mock that throws an exception
        Test.setMock(HttpCalloutMock.class, new MockHttpExceptionGenerator());
        
        // Call the method to test
        Test.startTest();
        String result = OpenAIAgent.askOpenAI('List all active users');
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Exception:'), 'Response should contain exception information');
    }
    
    // Exception-throwing mock
    public class MockHttpExceptionGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }
    
    // Test connection test method
    @isTest
    static void testConnectionMethod() {
        // Set the mock callout class
        Test.setMock(HttpCalloutMock.class, new MockConnectionTestResponseGenerator());
        
        // Call the method to test
        Test.startTest();
        String result = OpenAIAgent.testConnection();
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Connection test'), 'Response should contain connection test information');
    }
    
    // Mock for connection test
    public class MockConnectionTestResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('OpenAI API');
            return res;
        }
    }
    
    // Test UserLicenseHelper dependency
    @isTest
    static void testWithMockedUserLicenseHelper() {
        // First, setup the UserLicenseHelper mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Create and use a test implementation of UserLicenseHelper
        // Since we can't directly mock the UserLicenseHelper class, we'll create a test-specific override
        // This would ideally be a proxy or wrapper class that OpenAIAgent uses
        
        // Option: if UserLicenseHelper has static methods
        // Mock the result in your test by temporarily overriding the original implementation
        // This approach requires modification to UserLicenseHelper class to support test mocks
        
        // Call the method to test
        Test.startTest();
        String result = OpenAIAgent.askOpenAI('What licenses do we have?');
        Test.stopTest();
        
        // Verify results - in this case we're mostly testing that it runs without exceptions
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}