<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class BackupDatabase extends Command
{
    protected $signature = 'db:backup';

    protected $description = 'Create a backup of the MySQL database';

    public function handle()
    {
        $database = config('database.connections.mysql.database');
        $username = config('database.connections.mysql.username');
        $password = config('database.connections.mysql.password');
        $host = config('database.connections.mysql.host');
        $port = config('database.connections.mysql.port');

        $backupDirectory = storage_path('app/backups');

        if (!File::exists($backupDirectory)) {
            File::makeDirectory($backupDirectory, 0755, true);
        }

        $filename = 'backup_' . date('Y-m-d_H-i-s') . '.sql';

        $backupPath = $backupDirectory . DIRECTORY_SEPARATOR . $filename;

        $mysqldump = 'C:\\xampp\\mysql\\bin\\mysqldump.exe';

        if (!file_exists($mysqldump)) {
            $mysqldump = 'mysqldump';
        }

        $command = '"' . $mysqldump . '"'
            . ' --host=' . escapeshellarg($host)
            . ' --port=' . escapeshellarg($port)
            . ' --user=' . escapeshellarg($username);

        if (!empty($password)) {
            $command .= ' --password=' . escapeshellarg($password);
        }

        $command .= ' ' . escapeshellarg($database)
            . ' > ' . escapeshellarg($backupPath);

        exec($command, $output, $resultCode);

        if (
            $resultCode !== 0 ||
            !file_exists($backupPath) ||
            filesize($backupPath) === 0
        ) {
            if (file_exists($backupPath)) {
                File::delete($backupPath);
            }

            $this->error('Database backup failed.');

            return Command::FAILURE;
        }

        $this->info('Database backup created successfully.');

        $this->line('File: ' . $backupPath);

        return Command::SUCCESS;
    }
}