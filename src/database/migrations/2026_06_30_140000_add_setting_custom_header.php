<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
    $data = [
        'setting_key' => 'app-custom-head',
        'value' => "<style>\n  .export-format-pdf.export-engine-dompdf * {\n    font-family: 'nanum gothic', 'DejaVu Sans', sans-serif;\n  }\n</style>",
        'created_at' => Carbon::now(),
        'updated_at' => Carbon::now(),
        'type' => 'string',
    ];

    $exists = DB::table('settings')
        ->where('setting_key', 'app-custom-head')
        ->exists();

    if ($exists) {
        DB::table('settings')
            ->where('setting_key', 'app-custom-head')
            ->update([
                'value' => $data['value'],
                'updated_at' => Carbon::now(),
                'type' => 'string',
            ]);
    } else {
        DB::table('settings')->insert($data);
    }
}
    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')->where('setting_key', '=', 'app-custom-head')->delete();
    }
};
