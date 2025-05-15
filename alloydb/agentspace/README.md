# Agentspace

This repository provides deployment scripts for Agentspace integration with AlloyDB.


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
    * Provision the environment
   

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

**Note: At the moment, these steps will only work during the instructor-led Demo Fest and are not reproducible**

In this step, we are going to connect Agentspace to AlloyDB live data. Detailed steps are described in the [documentation](https://cloud.google.com/agentspace/agentspace-enterprise/docs/create-data-store#alloydb-connect), we are providing some scripts for simplified deployment.

- in cloud shell, run below comand, and paste the result in [this form](https://forms.gle/YzDkDJeownjEnxyL8)
```
gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)"
```
- run the following command to link Agentspace Enterprise with AlloyDB for PostgreSQL and define schema
```
gcp-database-demos/alloydb/agentspace/tf/files/agentspace-connect.sh
```
- In the Cloud Console, navigate to "AI Applications"
  - Create App
  - Select Agentspace and click Create
  - Provide a company name and click Continue
  - Select AlloyDB flights Data Store (which we created in the previous step)
  - Click Create
- Run below script to update UI configuration
```
gcp-database-demos/alloydb/agentspace/tf/files/agentspace-ui.sh
```
- Note: It might take a few minutes to all changes to propagate before the connector works!
- In your Application, navigate to Preview
  - Click "Sources" - if "AlloyDB - flights" is not visible yet, wait until it is
  - Try some queries such as:
  ```
  What flights are available from JFK to SFO on May 22 2025?
  What airlines fly from JFK to SFO?
  At what time does CY fly from JFK to SFO on May 22 2025?
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

 # License

This project is licensed under the [Apache License 2.0] 

## Disclaimer

This project is intended for demonstration purposes only. It is not an officially supported Google product and should not be used in production environments without careful consideration and appropriate modifications.