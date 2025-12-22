Raspberry PI Commands for server:

docker ps → shows running containers only
docker ps -a → shows all containers, including stopped ones

docker stop <container_name_or_id> -- stop it

docker rm <container_name_or_id> -- remove it

docker compose up -d -- Start Up detached

docker compose logs -f web -- watch error messages..


docker compose down --remove-orphans
docker compose build --no-cache
docker compose up



// Hope on to the container
docker compose exec web sh 
    then inside run to overwrite all the apps:
        cp -r /app/data/system-apps/apps/* /app/apps/


For my n2go API: FWS42T-HAUW2U-T8YR67-5MGA
Billboard API: 5c71545836mshbe319052ba9ca20p166291jsn5a5e8f066115
CPI Data: pWFw2e2zh7FzIdVmPJh7bVlqRi7hGZyYVFG1GM2Q
Congress: NFCjzaLhcELtQJdjibmJ1Dg3xuafCdtXSNiSwjDV
ATC: bbf223535bmshfde8e0174da351ap181512jsn1c51ea8eaa2b
Daily Kanji: 7d67711d22msh8861b592552e96dp14eb90jsnfd32c97dd1f1
Exchange Rate: ddce99f6bbf186fafc18ac18
CPI Data: ce1770178c514ff99d797487288b6c5f
