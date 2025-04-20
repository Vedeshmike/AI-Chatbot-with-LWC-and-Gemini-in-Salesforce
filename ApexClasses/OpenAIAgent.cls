public with sharing class OpenAIAgent {
    
    //private static final String OPENAI_ENDPOINT = 'https://api.openai.com/v1/chat/completions';
    private static final String OPENAI_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="Put your API Key Here"'; 
    //private static final String MODEL = 'google/gemini-2.0-flash-001'; // Updated model name
    
	@AuraEnabled
    public static String askOpenAI(String userQuery) {
        try {
            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(OPENAI_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
			req.setTimeout(120000); 
            

            // Step 1: Fetch Users via SOQL
            List<User> userList = [SELECT Name, Title, Department, Email FROM User WHERE IsActive = TRUE ];
            
            // Step 2: Convert User List to JSON-Compatible Format
            List<Map<String, String>> userJsonList = new List<Map<String, String>>();
            for (User u : userList) {
                Map<String, String> userMap = new Map<String, String>();
                userMap.put('Name', u.Name);
                userMap.put('Title', u.Title != null ? u.Title : 'No Title');
                userMap.put('Department', u.Department != null ? u.Department : 'No Department');
                userMap.put('Email', u.Email);
                userJsonList.add(userMap);
            }
            
            // Step 3: Convert to JSON String
            String userListJson = JSON.serialize(userJsonList);
            List<Map<String, Object>> licenseJsonList = UserLicenseHelper.getUserLicenseDetails();
            //String licenseListJson = JSON.serialize(licenseJsonList);
			//System.debug('LicenseList' +licenseListJson);
            
            // Step 4: Create JSON Structure for the Request
            List<Map<String, Object>> contentsList = new List<Map<String, Object>>();
            
            // Adding System Message (Must include role: "model")
            contentsList.add(new Map<String, Object>{
                'role' => 'model',
                    'parts' => new List<Map<String, Object>>{
                        new Map<String, Object>{ 
                            'text' => 'You are a Salesforce Admin Assistant. You help with Salesforce-related queries. Here is a list of active users in Salesforce: ' + userListJson +' And this is this List of Licenses available in the Org'+ licenseJsonList+'. Store this data for reference. '
                                }
                    }
            });
            
            // Adding Context as part of the user message
            contentsList.add(new Map<String, Object>{
                'role' => 'user',
                    'parts' => new List<Map<String, Object>>{
                        new Map<String, Object>{ 
                            'text' => 'You are a Salesforce Admin Assistant. You must strictly answer only based on the provided User and License data except for the Greetings. Keep responses concise and to the point. Now this is the User Query :' +'"' + userQuery + '"'
                                }
                    }
            });
            
            // Wrapping into final request
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('contents', contentsList);
            
            // Convert final request to JSON
            String requestBodyJson = JSON.serialize(requestBody);
            req.setBody(requestBodyJson);
            
            // Debug Request Information
            System.debug('=== REQUEST DETAILS ===');
            System.debug('Endpoint: ' + OPENAI_ENDPOINT);
            System.debug('Method: ' + req.getMethod());
            System.debug('Headers: ');
            System.debug('  Content-Type: ' + req.getHeader('Content-Type'));
            System.debug('  Authorization: Bearer ' + 'API_KEY_PRESENT');  // Don't log actual API key
            System.debug('Body: ' + requestBody);
            
            // Send Request
            Http http = new Http();
            System.debug('Sending request...');
            HTTPResponse res = http.send(req);
            
            // Debug Response Information
            System.debug('=== RESPONSE DETAILS ===');
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Status: ' + res.getStatus());
            System.debug('Response Headers: ');
            for (String headerKey : res.getHeaderKeys()) {
                System.debug('  ' + headerKey + ': ' + res.getHeader(headerKey));
            }
            System.debug('Response Body: ' + res.getBody());
            
            // Parse Response 
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                System.debug('Response Map: ' + responseMap);
                
                // Check for "candidates"
                List<Object> candidates = (List<Object>) responseMap.get('candidates');
                
                if (candidates != null && !candidates.isEmpty()) {
                    Map<String, Object> firstCandidate = (Map<String, Object>) candidates[0];
                    
                    // Extract "content" - it's a Map, NOT a List
                    Map<String, Object> contentMap = (Map<String, Object>) firstCandidate.get('content');
                    
                    if (contentMap != null) {
                        List<Object> parts = (List<Object>) contentMap.get('parts');
                        
                        
                        if (parts != null && !parts.isEmpty()) {
                            Map<String, Object> part = (Map<String, Object>) parts[0];
                            String text = (String) part.get('text');
                            
                            System.debug('Extracted Text: ' + text);
                            return text != null ? text.trim() : 'Error: No response text found';
                        } else {
                            return 'Error: No parts in content';
                        }
                        
                    } else {
                        return 'Error: No content in response';
                    }
                } else {
                    return 'Error: No candidates in response';
                }
            } else {
                return 'HTTP Error: Status Code ' + res.getStatusCode() + ' - ' + res.getStatus() + ' - ' + res.getBody();
            }


        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return 'Exception: ' + e.getTypeName() + ' - ' + e.getMessage() + ' - Line: ' + e.getLineNumber();
        }
    }
    
    // Test method to verify URL formatting and connectivity
    public static String testConnection() {
        try {
            // Test with a simple GET request to OpenAI's base URL
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.openai.com');
            req.setMethod('GET');
            req.setTimeout(30000);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            return 'Connection test - Status Code: ' + res.getStatusCode() + ', Status: ' + res.getStatus();
        } catch (Exception e) {
            return 'Connection test failed: ' + e.getMessage();
        }
    }
}
