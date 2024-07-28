DB = {}
function DB.FetchJobs()
    return MySQL.query.await('SELECT jobs FROM mri_qjobsystem')
end

function DB.InsertJobs(jobs)
    MySQL.insert('INSERT INTO mri_qjobsystem (jobs) VALUES (?)', {json.encode(jobs)})
end

function DB.SaveJobs(jobs)
    MySQL.update.await('UPDATE mri_qjobsystem SET jobs = ?', {json.encode(jobs)})
end

function DB.CreateTable()
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `mri_qjobsystem` (
            `jobs` longtext
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])
end
