# Agentspace

This repository provides deployment scripts for Agentspace integration with AlloyDB.

Note: This demo is currently designed for instructor-led labs.

## Getting Started

1. **Prerequisites:**
    * GCP Environment with sufficiently broad permissions to create various resources

2. **Deployment:**
    * Create a project to host your deployment. We recommend an empty project to avoid any unforseen issues.
    * Open Cloud Shell and set your target project as the current project (this guide assumes you are using cloud shell!)
    * Run these commands:
    ```
    git clone https://github.com/jk-kashe/gcp-database-demos
    cd gcp-database-demos/alloydb/agentspace
    make apply
    ```
    * Deployment script ask you to provide variable values. Most variables should be auto-populated, but check they are correct. It's assumed you have the knowledge of GCP to find the correct values!
      * Set AlloyDB password to a reasonably secure one
      * **Agentpsace AlloyDB Instance Path** will be provided by your instructor
    * Provision the environment
    * While your environment is being provisioned - in a separate cloud shell, run below comand, and paste the result in [this form](https://forms.gle/YzDkDJeownjEnxyL8)
```
gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)"
```
   

## Demo Scenarios

### 1. Importing Data from AlloyDB

- Run these commands:
    ```
    gcp-database-demos/alloydb/agentspace/tf/files/agentspace-import.sh
    ```
- In the search box, navigate to AI Applications.
  - Activate the API.
  - Create an Agentspace app, associating all existing data stores with it.
  - Try different queries over the imported data

### 2. Querying Live Data using Natural Language from AlloyDB


In this step, we are going to connect Agentspace to AlloyDB live data. Detailed steps are described in the [documentation](https://cloud.google.com/agentspace/agentspace-enterprise/docs/create-data-store#alloydb-connect). Terraform script creates the configuration and connector.



- In the Cloud Console, navigate to "AI Applications"
  - Create App
  - Select Agentspace and click Create
  - Provide a company name and click Continue
  - Select 'Flights and Airports Data' (created by terraform)
  - Click Create
 
- Due to the nature of the usecase, the agent is likely to use google_search tool and public datasets. You will get better results by writing custom instructions to use "Flights and Airports Data" and disabling grounding in Google search.

- Note: It might take a few minutes to all changes to propagate before the connector works!
- In your Application, navigate to Preview
  - Click "Sources" - if "AlloyDB Live Data" is not visible yet, wait until it is
  - Try some queries such as:
  ```
  What flights are available from JFK to SFO on May 22 2025?
  What airlines fly from JFK to SFO?
  At what time does CY fly from JFK to SFO on May 22 2025?
  Where can I find coffee?
  May I change my ticket?
  ```


### 3. Building an Agent for flights booking

* In a new tab, go to [http://conversational-agents.cloud.google.com] and select your project.
* Create a new "build your own" agent, ensuring that you use the Playbook option for conversation start.
* Set the goal to:
```
You are a travel agent.
```
* Create a new tool, using the OpenAPI spec from `tf/files/agentspace-openapi.yaml` and the prompt:
```
This tool is used to look up flight information and manage ticket bookings. It offers the following operations:
- get_airport: Gets the details for the airport specified by either ID or IATA code
- search_airports: Searches for airports based on country, city or name
- get_amenity: Gets a specific amenity by ID
- search_amenities: Searches for amenities based on a provided query
- get_flight: Gets a flight by ID
- search_flights: Searches for flights based on departure airport, arrival airport, date, flight number or airline
- list_tickets: List the tickets purchased by the logged in user
- insert_ticket: Books a ticket for the logged in user
- validate_ticket: Validates the ticket details
```
* Associate the tool with the default playbook.
* Go back to [http://conversational-agents.cloud.google.com] and copy the agent URL.
* Add `service-[PROJECT_NUMBER]@gcp-sa-dialogflow.iam.gserviceaccount.com` to the `Cloud Run Invoker` role on the Cloud Run service.
* Go to the Configurations section of the Agentspace app and click on Assistant.
* Enter the following LLM system instructions:
```
You are a booking agent for Cymbal Air. You have access to the following connected data stores:
- Cymbal Air Airports: This contains a list of all the airports in the world, along with their location and IATA code.
- Cymbal Air Amenities: This contains a list of amenities in the airport with IATA code SFO. This does not contain amenity information for any other airport. Use this when someone asks for information about available amenities.
- Cymbal Air Flights: This contains a list of flights that can be booked, along with departure and arrival information. Use this when someone asks about available flights.
- Cymbal Air Policies: This contains a list of booking policies.
- Cymbal Air Tickets: This contains a list of booked flight tickets. Use this when someone asks about their booked flights.
```
* Add an agent and paste in the copied agent link, removing `https://conversational-agents.cloud.google.com/` from the start and `/playbooks/[PLAYBOOK_ID]` from the end. Use the following instructions:
```
Use to find flight information and book a flight.
- When searching for flight information, send the user's prompt and append on the end "Format the results as a table".
- When making a booking use the following prompt, replacing the placeholders as needed: "Book a flight from ${departure airport} to ${arrival airport} on ${departure date and time} for ${name},  ${e-mail address}. Book the first flight you find."
```
* Click on Save and Publish.

## Demo Flow

1. Start by asking a question like "What flights are available from JFK to SFO on Sept 15 2025"
2. You can update one of the flights in the backend 
```sql
UPDATE flights 
SET
  arrival_time = arrival_time + INTERVAL '4 hours',
  departure_time = departure_time + INTERVAL '4 hours',
  departure_gate = (ARRAY['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'])[floor(random() * 12) + 1] || floor(random() * 113 + 1)::text
WHERE
  id = 50695; --use a relevant flight id
```

3. You can showcase that the agent is using live data by asking for an update, e.g. "what's the new flight information for B6 415 on September 15 2025"
4. You can even run queries over embeddings, e.g. "where can I find coffee at terminal 1"
```

 # License

This project is licensed under the [Apache License 2.0] 

## Disclaimer

This project is intended for demonstration purposes only. It is not an officially supported Google product and should not be used in production environments without careful consideration and appropriate modifications.
