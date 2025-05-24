function updateDashboard() {
    fetch('/get_votes')
        .then(response => response.json())
        .then(data => {
            const tableBody = document.getElementById('vote-table-body');
            tableBody.innerHTML = ''; // Clear existing rows
            data.forEach(item => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${item.party_name}</td>
                    <td>${item.vote_count}</td>
                `;
                tableBody.appendChild(row);
            });
        })
        .catch(error => {
            console.error('Error fetching vote data:', error);
            const tableBody = document.getElementById('vote-table-body');
            tableBody.innerHTML = '<tr><td colspan="2">Error loading vote data</td></tr>';
        });
}

// Initial load
updateDashboard();

// Poll every 5 seconds
setInterval(updateDashboard, 5000);