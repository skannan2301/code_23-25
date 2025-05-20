# Transferring Surveys Master Script
# What do I do?
  # I ask you which study you're trying to transfer surveys for (options being: GAIN, NMDA, Pelican Eagles, Pelican ASF)
  # You respond (can be all lowercase)
  # I ask you to give me the csv filepath, OR the .exp filepath
  # I ask you where you want to save the file to
  # I go to the chunk of code specialized for that particular survey export
  # I spit out the cleaned CSV for you to input into REDCap's import data function

import os
import sys
from datetime import datetime
import pandas as pd

### User input section ###
# Ask for study name
study = input("Which study are you transferring surveys for? ").strip().lower()

# Ask for CSV file path
csv_path = input("Enter the path to the CSV or .exp file: ").strip()

# Check if file exists
if not os.path.exists(csv_path):
    print("File does not exist.")
    exit()

# Try to read the CSV
try:
    data = pd.read_csv(csv_path)
    print(f"CSV loaded successfully with {len(data)} rows.")
except Exception as e:
    print(f"Error reading CSV: {e}")
    exit()

# Ask for save directory
save_dir = input("Enter the directory where you'd like to save the output CSV: ").strip()

# Check if directory exists
if not os.path.isdir(save_dir):
    print("Save directory does not exist.")
    exit()

### functions ###
# functions (to be added to)
def remove_cols(cols_to_remove, data, value=None):
    existing_cols_to_remove = [col for col in cols_to_remove if col in data.columns]
    data = data.drop(columns=existing_cols_to_remove)
    print(f"Removed columns: {existing_cols_to_remove}")
def duplicate_ID(data):
    # Get the name of the first column
    first_col = data.columns[0]

    # Create a duplicate DataFrame
    duplicated_data = data.copy()

    # Modify first column in original
    data[first_col] = data[first_col].astype(str) + "--1"

    # Modify first column in duplicate
    duplicated_data[first_col] = duplicated_data[first_col].astype(str) + "--2"

    # Concatenate both dataframes
    final_data = pd.concat([data, duplicated_data], ignore_index=True)

    print("Duplicated rows and updated identifiers in first column.")

    # Get filename components
    first_value = str(final_data.iloc[0][first_col])
    prefix = first_value[:9]
    date_str = datetime.today().strftime("%Y%m%d")
    filename = f"{prefix}_{study}_{date_str}_surveys.csv"

    # Full path to save
    full_path = os.path.join(save_dir, filename)

    # Save the file
    final_data.to_csv(full_path, index=False)
    print(f"Final data saved to:\n{full_path}")

### actual survey transferring section ###
# Branch logic
if study == "pelican eagles":
    print("Processing Pelican Eagles data...")

    # Columns to remove
    cols_to_remove = [
        "visit_questionnaires___econsents",
        "visit_questionnaires___ace_subject_medical_history",
        "visit_questionnaires___pddbi",
        "visit_questionnaires___srs2_preschool",
        "visit_questionnaires___bascpresch",
        "recordid_age",
        "econsents_timestamp",
        "econsents_first_name",
        "econsents_last_name",
        "econsent_signature",
        "econsent_date_signed",
        "econsents_complete",
        "previsit_notes",
        "previsit_language",
        "previsit_instructionsresp",
        "previsit_sensoryresp",
        "previsit_parentseparation",
        "previsit_videoprefs",
        "previsit_reinforcers",
        "previsit_downtime",
        "previsit_reinforcesystems",
        "previsit_bringalong",
        "previsit_visualsupports",
        "previsit_triggers",
        "previsit_stressbeh",
        "previsit_toilettrained",
        "previsit_aggression",
        "previsit_selfinjury",
        "previsit_elopement",
        "previsit_otherbeh",
        "previsit_behresp",
        "previsit_cooldown",
        "previsit_writing",
        "iep_report",
        "previsit_othernotes",
        "previsit_information_complete",
        "video_links",
        "video_links_complete",
        "srs2_preschool_timestamp",
        "srs2_preschool_complete"
    ]

    # Drop only existing columns
    remove_cols(cols_to_remove, data)

    # duplicate record ID (get --1 and --2)
    duplicate_ID(data)
elif study == "pelican asf":
    print("Processing Pelican ASF data...")
    cols_to_remove = [
        "visit_questionnaires___econsents",
        "visit_questionnaires___ace_subject_medical_history",
        "visit_questionnaires___pddbi",
        "visit_questionnaires___srs2_preschool",
        "visit_questionnaires___bascpresch",
        "recordid_age",
        "econsents_timestamp",
        "econsents_first_name",
        "econsents_last_name",
        "econsent_signature",
        "econsent_date_signed",
        "econsents_complete",
        "previsit_notes",
        "previsit_language",
        "previsit_instructionsresp",
        "previsit_sensoryresp",
        "previsit_parentseparation",
        "previsit_videoprefs",
        "previsit_reinforcers",
        "previsit_downtime",
        "previsit_reinforcesystems",
        "previsit_bringalong",
        "previsit_visualsupports",
        "previsit_triggers",
        "previsit_stressbeh",
        "previsit_toilettrained",
        "previsit_aggression",
        "previsit_selfinjury",
        "previsit_elopement",
        "previsit_otherbeh",
        "previsit_behresp",
        "previsit_cooldown",
        "previsit_writing",
        "iep_report",
        "previsit_othernotes",
        "previsit_information_complete",
        "video_links",
        "video_links_complete",
        "srs2_preschool_timestamp",
        "srs2_preschool_complete"
    ]

    # Drop only existing columns
    remove_cols(cols_to_remove, data)

    # Get the name of the first column
    first_col = data.columns[0]

    duplicate_ID(data)
elif study == "flamingo":
    print("Processing Flamingo data...")
    do = input("Are you transferring SRS (1) or transferring the BASC (2)? ").strip().lower()
    record_id = [id.strip() for id in input("Which ID? ")]
    if do == "1":
        print("Processing SRS data...")

        # Load the file (adjust sep if needed)
        df = pd.read_csv(csv_path, sep=r'[\t,]', engine='python')

        # Columns you want to keep and rename
        columns_to_keep = [
            "T-Awr", "T-Cog", "T-Com", "T-Mot", "T-RRB",
            "T-Score", "T-SCI", "T-RRB.1"
        ]

        # Select only those columns
        df_filtered = df[columns_to_keep]

        # Rename mapping
        rename_dict = {
            "T-Awr": "srs2_schoolage_awr_tscore",
            "T-Cog": "srs2_schoolage_cog_tscore",
            "T-Com": "srs2_schoolage_comm_tscore",
            "T-Mot": "srs2_schoolage_mot_tscore",
            "T-RRB": "srs2_schoolage_rrb_tscore",
            "T-Score": "srs2_schoolage_tot_tscore",
            "T-SCI": "srs2_schoolage_sci_tscore",
            "T-RRB.1": "srs2_schoolage_rrbdsm5_tscore"
        }

        # Apply renaming
        df_filtered = df_filtered.rename(columns=rename_dict)

        # Save to CSV
        df_filtered.to_csv("filtered_renamed_output.csv", index=False)

        print("Renamed CSV saved as 'filtered_renamed_output.csv'")

    elif do == "2":
        print("Processing BASC data...")

        # Columns to remove
        cols_to_remove = ["FirstName", "MiddleName", "LastName", "BirthDate", "Form", "Examiner", "School", "Grade",
                          "GradeOther", "Custom1", "Custom2", "Custom3", "Custom4", "Language", "AdminTime",
                          "RaterFirstName", "RaterMI", "RaterLastName", "Position", "PositionOther", "TimeKnown",
                          "RaterGender", "RelationOther", "ConcernVision", "ConcernHearing", "ConcernEatingHabits",
                          "Enrollment", "StrengthsComment", "ConcernsComment"]

        # Drop only existing columns
        remove_cols(cols_to_remove, data)

        data.at[0, 'ConfidenceLevel'] = '90'
        data.at[0, 'NormGroup'] = 'Gender Specific'

        # Insert a new empty column at position 1 (second column)
        data.insert(loc=1, column='redcap_event_name', value='')

        # Add value to row 2 (index 1)
        data.at[0, 'redcap_event_name'] = 'participant_data_arm_1'

        # Your custom column names
        new_column_names = [
            "subject_id_info", "redcap_event_name", "basc_a_gs_gender", "basc_gs_doe", "basc_a_gs_age_eval",
            "basc_a_gs_responder", "basc_a_gs_ci_raw", "basc_a_gs_ci_cat", "basc_a_gs_findex_raw",
            "basc_a_gs_findex_cat",
            "basc_a_gs_rpi_raw", "basc_a_gs_rpi_cat", "basc_a_gs_confidence", "basc_a_gs_norm_group",
            "basc_a_gs_ad_raw",
            "basc_a_gs_dl_raw", "basc_a_gs_ag_raw", "basc_a_gs_ax_raw", "basc_a_gs_ap_raw", "basc_a_gs_ay_raw",
            "basc_a_gs_cp_raw", "basc_a_gs_dp_raw", "basc_a_gs_fc_raw", "basc_a_gs_ha_raw", "basc_a_gs_le_raw",
            "basc_a_gs_so_raw", "basc_a_gs_sm_raw", "basc_a_gs_wd_raw", "basc_a_gs_ac_raw", "basc_a_gs_bl_raw",
            "basc_a_gs_sd_raw", "basc_a_gs_sc_raw", "basc_a_gs_ef_raw", "basc_a_gs_ne_raw", "basc_a_gs_rs_raw",
            "basc_a_gs_adhd_raw", "basc_a_gs_aut_raw", "basc_a_gs_ebd_raw", "basc_a_gs_fi_raw", "basc_a_gs_ps_raw",
            "basc_a_gs_att_raw", "basc_a_gs_bc_raw", "basc_a_gs_ec_raw", "basc_a_gs_oef_raw", "basc_a_gs_as_tsum",
            "basc_a_gs_bs_tsum", "basc_a_gs_ep_tsum", "basc_a_gs_ip_tsum", "basc_a_gs_ad_primt", "basc_a_gs_dl_primt",
            "basc_a_gs_ag_primt", "basc_a_gs_ax_primt", "basc_a_gs_ap_primt", "basc_a_gs_ay_primt",
            "basc_a_gs_cp_primt",
            "basc_a_gs_dp_primt", "basc_a_gs_fc_primt", "basc_a_gs_ha_primt", "basc_a_gs_le_primt",
            "basc_a_gs_so_primt",
            "basc_a_gs_sm_primt", "basc_a_gs_wd_primt", "basc_a_gs_ac_primt", "basc_a_gs_bl_primt",
            "basc_a_gs_sd_primt",
            "basc_a_gs_sc_primt", "basc_a_gs_ef_primt", "basc_a_gs_ne_primt", "basc_a_gs_rs_primt",
            "basc_a_gs_adhd_primt",
            "basc_a_gs_aut_primt", "basc_a_gs_ebd_primt", "basc_a_gs_fi_primt", "basc_a_gs_as_tscore",
            "basc_a_gs_bs_tscore",
            "basc_a_gs_ep_tscore", "basc_a_gs_ip_tscore", "basc_a_gs_ed_index_1_raw", "basc_a_gs_ed_index_2_raw",
            "basc_a_gs_ed_index_3_raw", "basc_a_gs_ed_index_4_raw", "basc_a_gs_ed_index_5_raw",
            "basc_a_gs_ed_index_1_t",
            "basc_a_gs_ed_index_2_t", "basc_a_gs_ed_index_3_t", "basc_a_gs_ed_index_4_t", "basc_a_gs_ed_index_5_t",
            "basc_a_gs_ed_index_1_per", "basc_a_gs_ed_index_2_per", "basc_a_gs_ed_index_3_per",
            "basc_a_gs_ed_index_4_per",
            "basc_a_gs_ed_index_5_per", "basc_a_gs_ed_index_1_clin", "basc_a_gs_ed_index_2_clin",
            "basc_a_gs_ed_index_3_clin",
            "basc_a_gs_ed_index_4_clin", "basc_a_gs_ed_index_5_clin", "basc_a_gs_smi"
        ]

        # Get number of actual columns in data
        actual_col_count = len(data.columns)
        desired_col_count = len(new_column_names)

        # Pad column names with auto-generated extras
        if actual_col_count > desired_col_count:
            for i in range(actual_col_count - desired_col_count):
                new_column_names.append(f"extra_col_{i + 1}")
            print(f"Added {actual_col_count - desired_col_count} extra column name(s).")

        # Assign all new column names
        data.columns = new_column_names
        print("Column names replaced successfully (with extras padded).")

        # Save with dynamic filename
        #date_str = datetime.today().strftime("%Y%m%d")
        #filename = f"basc-3_{data.iloc[0]['subject_id_info']}_{date_str}_halfway.csv"
        #halfway_path = os.path.join(save_dir, filename)
        #data.to_csv(halfway_path, index=False)
        #print(f"1step data saved to:\n{halfway_path}")

        # cleaning up blanks
        # 1. Extract row 2 (index 0?? --> maybe it doesn't register the header columns), filter out blanks/NaNs, then pad with NAs to original length
        row2 = data.iloc[0].tolist()
        non_blanks = [v for v in row2 if pd.notna(v) and v != ""]
        new_row2 = non_blanks + [pd.NA] * (len(row2) - len(non_blanks))

        # 2. Assign the compacted row back into the DataFrame
        data.iloc[0] = new_row2

        # 3. Drop any auto-generated extra_col_* columns
        extra_cols = [col for col in data.columns if col.startswith("extra_col_")]
        if extra_cols:
            data.drop(columns=extra_cols, inplace=True)
            print(f"Dropped {len(extra_cols)} placeholder column(s): {extra_cols}")

        # 4. Save final CSV
        date_str = datetime.today().strftime("%Y%m%d")
        filename = f"basc-3_{data.iloc[0]['subject_id_info']}_{date_str}.csv"
        full_path = os.path.join(save_dir, filename)
        data.to_csv(full_path, index=False)
        print(f"Final data saved to:\n{full_path}")

    else:
        print("Invalid choice. Please enter 1 or 2.")
        sys.exit(1)
elif study == "gain":
    do = input("Are you transferring surveys (1), transferring the MIST-A (2), transferring Qualtrics data (3), or transferring EMA (4)? ").strip().lower()

    if do == "1":
        print("Processing GAIN survey data...")
        # Columns to remove
        cols_to_remove = [
            "survey_id",
            "ses_a_sp_emp_score",
            "ses_c_par1_emp_score",
            "ses_c_par2_emp_score"
        ]

        # Drop only existing columns
        remove_cols(cols_to_remove, data)

        # get --1 and --2 rows
        duplicate_ID(data)

    elif do == "2":
        print("Processing MIST-A data...")

    elif do == "3":
        print("Processing Qualtrics data...")
        # Get multiple IDs from user input
        ids_to_pull = [id.strip() for id in input("Which ID(s)? Separate with commas: ").split(',')]
        data = data[data["Q40"].isin(ids_to_pull)]
        print("Processing gain qualtrics data...")

        # Columns to remove
        cols_to_remove = [
            "StartDate", "EndDate", "Status", "IPAddress", "Progress", "Duration (in seconds)", "Finished",
            "RecordedDate", "ResponseId", "RecipientLastName", "RecipientFirstName", "RecipientEmail",
            "ExternalReference", "LocationLatitude", "LocationLongitude", "DistributionChannel", "UserLanguage",
            "Q94_1", "Q94_2", "Q94_3", "Q94_4", "Q94_5", "Q94_6", "Q94_7", "Q94_8",
            "Random ID", "Create New Field or Choose From Dropdown..."
        ]

        # Drop only existing columns
        remove_cols(cols_to_remove, data)

        # Replace remaining column names with new names
        new_column_names = [
            "record_id", "sound_q1", "sound_q2", "sound_q3", "sound_q4",
            "aasp1", "aasp2", "aasp3", "aasp4", "aasp5", "aasp6", "aasp7", "aasp8", "aasp9", "aasp10",
            "aasp11", "aasp12", "aasp13", "aasp14", "aasp15", "aasp16", "aasp17", "aasp18", "aasp19", "aasp20",
            "aasp21", "aasp22", "aasp23", "aasp24", "aasp25", "aasp26", "aasp27", "aasp28", "aasp29", "aasp30",
            "aasp31", "aasp32", "aasp33", "aasp34", "aasp35", "aasp36", "aasp37", "aasp38", "aasp39", "aasp40",
            "aasp41", "aasp42", "aasp43", "aasp44", "aasp45", "aasp46", "aasp47", "aasp48", "aasp49", "aasp50",
            "aasp51", "aasp52", "aasp53", "aasp54", "aasp55", "aasp56", "aasp57", "aasp58", "aasp59", "aasp60",
            "mist_a_1", "mist_a_2", "mist_a_3", "mist_a_4", "mist_a_5", "mist_a_6", "mist_a_7", "mist_a_8",
            "mist_a_9", "mist_a_10", "mist_a_11", "mist_a_12", "mist_a_13", "mist_a_14", "mist_a_15", "mist_a_16",
            "mist_a_17", "mist_a_18", "mist_a_19", "mist_a_20", "mist_a_21", "mist_a_22", "mist_a_23", "mist_a_24",
            "mist_a_25", "mist_a_26", "mist_a_27", "mist_a_28", "mist_a_29", "mist_a_30", "mist_a_31", "mist_a_32",
            "mist_a_33", "mist_a_34", "gsq_1", "gsq_2", "gsq_3", "gsq_4", "gsq_5", "gsq_6", "gsq_7", "gsq_8", "gsq_9",
            "gsq_10", "gsq_11", "gsq_12", "gsq_13", "gsq_14", "gsq_15", "gsq_16", "gsq_17", "gsq_18", "gsq_19", "gsq_20",
            "gsq_21", "gsq_22", "gsq_23", "gsq_24", "gsq_25", "gsq_26", "gsq_27", "gsq_28", "gsq_29", "gsq_30",
            "gsq_31", "gsq_32", "gsq_33", "gsq_34", "gsq_35", "gsq_36", "gsq_37", "gsq_38", "gsq_39", "gsq_40",
            "gsq_41", "gsq_42",
            "sgi_1", "sgi_2", "sgi_3", "sgi_4", "sgi_5", "sgi_6", "sgi_7", "sgi_8", "sgi_9", "sgi_10",
            "sgi_11", "sgi_12", "sgi_13", "sgi_14", "sgi_15", "sgi_16", "sgi_17", "sgi_18", "sgi_19", "sgi_20",
            "sgi_21", "sgi_22", "sgi_23", "sgi_24", "sgi_25", "sgi_26", "sgi_27", "sgi_28", "sgi_29", "sgi_30",
            "sgi_31", "sgi_32", "sgi_33", "sgi_34", "sgi_35", "sgi_36",
            "srs_a_sr_q01", "srs_a_sr_q02", "srs_a_sr_q03", "srs_a_sr_q04", "srs_a_sr_q05", "srs_a_sr_q06",
            "srs_a_sr_q07", "srs_a_sr_q08", "srs_a_sr_q09", "srs_a_sr_q10",
            "srs_a_sr_q11", "srs_a_sr_q12", "srs_a_sr_q13", "srs_a_sr_q14", "srs_a_sr_q15", "srs_a_sr_q16",
            "srs_a_sr_q17", "srs_a_sr_q18", "srs_a_sr_q19", "srs_a_sr_q20",
            "srs_a_sr_q21", "srs_a_sr_q22", "srs_a_sr_q23", "srs_a_sr_q24", "srs_a_sr_q25", "srs_a_sr_q26",
            "srs_a_sr_q27", "srs_a_sr_q28", "srs_a_sr_q29", "srs_a_sr_q30",
            "srs_a_sr_q31", "srs_a_sr_q32", "srs_a_sr_q33", "srs_a_sr_q34", "srs_a_sr_q35", "srs_a_sr_q36",
            "srs_a_sr_q37", "srs_a_sr_q38", "srs_a_sr_q39", "srs_a_sr_q40",
            "srs_a_sr_q41", "srs_a_sr_q42", "srs_a_sr_q43", "srs_a_sr_q44", "srs_a_sr_q45", "srs_a_sr_q46",
            "srs_a_sr_q47", "srs_a_sr_q48", "srs_a_sr_q49", "srs_a_sr_q50",
            "srs_a_sr_q51", "srs_a_sr_q52", "srs_a_sr_q53", "srs_a_sr_q54", "srs_a_sr_q55", "srs_a_sr_q56",
            "srs_a_sr_q57", "srs_a_sr_q58", "srs_a_sr_q59", "srs_a_sr_q60",
            "srs_a_sr_q61", "srs_a_sr_q62", "srs_a_sr_q63", "srs_a_sr_q64", "srs_a_sr_q65",
            "srs_a_sr_awr_raw", "srs_a_sr_cog_raw", "srs_a_sr_comm_raw", "srs_a_sr_mot_raw", "srs_a_sr_sci",
            "srs_a_sr_rrb_raw", "srs_a_sr_raw"
            ]

        # Replace remaining column names with new names (add blank columns if needed)
        if len(data.columns) < len(new_column_names):
            missing_cols = len(new_column_names) - len(data.columns)
            print(f"Original data has {len(data.columns)} columns. Padding with {missing_cols} empty columns.")

            # Add empty columns
            for i in range(missing_cols):
                data[f"placeholder_{i + 1}"] = ""

        # Now ensure we only assign the exact number of new column names
        data = data.iloc[:, :len(new_column_names)]
        data.columns = new_column_names
        print("Column names replaced successfully.")

        # Duplicate rows and modify record_id
        duplicated_data = data.copy()
        data["record_id"] = data["record_id"].astype(str) + "--1"
        duplicated_data["record_id"] = duplicated_data["record_id"].astype(str) + "--2"
        final_data = pd.concat([data, duplicated_data], ignore_index=True)
        print("Duplicated rows and modified 'record_id'.")

        # Generate filename
        #first_value = str(data.iloc[0]["record_id"])
        #prefix = first_value[:9]
        date_str = datetime.today().strftime("%Y%m%d")
        filename = f"{ids_to_pull}_gain_{date_str}_surveys.csv"
        full_path = os.path.join(save_dir, filename)

        # Save output
        final_data.to_csv(full_path, index=False)
        print(f"Final data saved to:\n{full_path}")

    elif do == "4":
        print("Processing EMA data...")

        # --- USER INPUTS ---
        record_id = [id.strip() for id in input("Which ID(s)? Separate with commas: ").split(',')]
        filename = f"{'_'.join(record_id)}_EMA.csv"  # Modified to handle multiple IDs
        output_file = os.path.join(save_dir, filename)

        # --- LOAD DATA ---
        df = pd.read_csv(csv_path)

        # --- SPLIT RecordedDate into date and time ---
        df[['date1', 'timea']] = df['RecordedDate'].str.split(' ', n=1, expand=True)

        # --- PARSE date1 into datetime.date ---
        df['date1'] = pd.to_datetime(df['date1'], errors='coerce', infer_datetime_format=True).dt.date

        # --- REMOVE time column ---
        df = df.drop(columns=['timea'])

        # --- REMOVE unwanted columns ---
        columns_to_remove = [
            "StartDate", "EndDate", "Status", "IPAddress", "Progress",
            "Duration..in.seconds.", "Finished", "ResponseId",
            "RecipientLastName", "RecipientFirstName", "RecipientEmail",
            "LocationLatitude", "LocationLongitude", "DistributionChannel",
            "UserLanguage"
        ]
        remove_cols(columns_to_remove, df)

        # --- FILTER by record_id ---
        df = df[df['ExternalReference'].astype(str).isin(record_id)]

        # --- GROUP and calculate date_diff ---
        df['day1'] = df.groupby('ExternalReference')['date1'].transform('first')
        df['date_diff'] = (pd.to_datetime(df['date1']) - pd.to_datetime(df['day1'])).dt.days + 1

        # --- REMOVE date1 column ---
        df = df.drop(columns=['date1'])

        # --- PIVOT to wide format ---
        value_cols_start = df.columns.get_loc('Distract')
        value_cols_end = df.columns.get_loc('randomID')
        value_cols = df.columns[value_cols_start:value_cols_end + 1].tolist()

        df_wide = df.pivot_table(
            index='ExternalReference',
            columns='date_diff',
            values=value_cols,
            aggfunc='first'
        )

        # Flatten the MultiIndex columns and format as d{day}_{question}
        df_wide.columns = [f'd{int(day)}_{col}' for col, day in df_wide.columns]
        df_wide = df_wide.reset_index()

        # --- RENAME ExternalReference to record_id ---
        df_wide = df_wide.rename(columns={'ExternalReference': 'record_id'})

        # --- CLEAN column names ---
        df_wide.columns = df_wide.columns.str.replace(r'[^a-zA-Z0-9_]', '', regex=True).str.lower()

        # --- DUPLICATE rows based on record_id ---
        duplicated_rows = []

        for record in df_wide['record_id'].unique():
            subset = df_wide[df_wide['record_id'] == record].copy()

            subset_1 = subset.copy()
            subset_1['record_id'] = subset_1['record_id'] + '--1'

            subset_2 = subset.copy()
            subset_2['record_id'] = subset_2['record_id'] + '--2'

            duplicated_rows.append(subset_1)
            duplicated_rows.append(subset_2)

        duplicated_df = pd.concat(duplicated_rows, ignore_index=True)

        # --- SAVE TO CSV ---
        duplicated_df.to_csv(output_file, index=False)
        print(f"Saved to {output_file}")

    else:
        print("Invalid option.")
elif study == "nmda":
    print("Processing NMDA data...")

    # Columns to remove
    cols_to_remove = [
        "survey_id",
        "ses_a_sp_emp_score",
        "ses_c_par1_emp_score",
        "ses_c_par2_emp_score",
        "record_id_info_timestamp",
        "record_id_1",
        "record_id_info_complete",
        "stop_here_timestamp",
        "stop_here_complete",
        "stop_here_2_timestamp",
        "stop_here_2_complete",
        "stop_here_3_timestamp",
        "stop_here_3_complete",
        "stop_here_4_timestamp",
        "stop_here_4_complete",
        "stop_here_5_timestamp",
        "stop_here_5_complete",
        "stop_here_6_timestamp",
        "stop_here_6_complete"
    ]

    # Drop only existing columns
    remove_cols(cols_to_remove, data)

    # Get the name of the first column
    first_col = data.columns[0]

    # Create a duplicate (--1 and --2)
    duplicate_ID(data)
else:
    print("Study not recognized.")
