import bz2
import xml.etree.ElementTree as ET
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import argparse

import pandas as pd
import datetime

def safe_to_bigint(value):
    try:
        return int(value)
    except (ValueError, TypeError):
        return 0

def safe_to_timestamptz(value):
    try:
        return pd.to_datetime(value, format='%Y-%m-%dT%H:%M:%SZ', utc=True)
    except (ValueError, TypeError):
        return None

def safe_to_int(value):
    try:
        return int(value)
    except (ValueError, TypeError):
        return 0

def safe_to_double(value):
    try:
        return float(value)
    except (ValueError, TypeError):
        return 0.



def convert_xml_to_parquet(input_file, output_file, chunk_size):

    data_chunk = []
    first_chunk = True  # To initialize the ParquetWriter only once
    writer = None
    row_counter = 0

    # Open and stream the XML and Initialize iterparse to stream through XML file
    with bz2.open(input_file, "rt") as file:
        for event, element in ET.iterparse(file, events=("end",)):
            # Process each "changeset" element
            if element.tag == 'changeset':
                # Extract attributes and nested tags
                record_data = {
                    'id': safe_to_bigint(element.get('id')),
                    'created_at': pd.to_datetime(element.get('created_at'), format='%Y-%m-%dT%H:%M:%SZ', utc=True),
                    'closed_at': pd.to_datetime(element.get('closed_at'), format='%Y-%m-%dT%H:%M:%SZ', utc=True),
                    'uid': safe_to_int(element.get('uid')),
                    'user': element.get('user'),
                    'num_changes': safe_to_int(element.get('num_changes')),
                    'min_lat': safe_to_double(element.get('min_lat')),
                    'min_lon': safe_to_double(element.get('min_lon')),
                    'max_lat': safe_to_double(element.get('max_lat')),
                    'max_lon': safe_to_double(element.get('max_lon')),

                    # Set default values for tags that might be missing in chunk
                    'created_by': '',
                    'imagery_used': '',
                    'host': '',
                    # number of changesets the user has made before the current one
                    # only works for Id and Rapid, will be calculated in database instead
                    # 'changesets_count': '',
                    'hashtags': ''                    
                }
                
                for tag in element.findall('tag'):
                    if tag.get('k') == 'created_by':
                        record_data['created_by'] = tag.get('v')
                    elif tag.get('k') == 'imagery_used':
                        record_data['imagery_used'] = tag.get('v')
                    elif tag.get('k') == 'host':
                        record_data['host'] = tag.get('v')
                    elif tag.get('k') == 'hashtags':
                        record_data['hashtags'] = tag.get('v')
                
                # Add record to the current chunk and free up memory
                data_chunk.append(record_data)
                element.clear()
                
                # If chunk size is reached, write the chunk to Parquet
                if len(data_chunk) >= chunk_size:
                    # print(f"Writing chunk of size {len(data_chunk)} to Parquet.")
                    df_chunk = pd.DataFrame(data_chunk)                    
                    table = pa.Table.from_pandas(df_chunk)

                    #Initialize Parquet file with the first chunk
                    if writer is None: 
                        writer = pq.ParquetWriter(output_file, table.schema.remove_metadata(), compression='snappy', use_dictionary=True)
                    
                    # Write or append chunks to the Parquet file
                    if first_chunk:
                        writer.write_table(table)
                        first_chunk = False
                        print(f"{datetime.datetime.now().strftime('%H:%M:%S')} First chunk was written to {output_file}")
                    else:
                        writer.write_table(table)
                    
                    # Clear the chunk data
                    data_chunk = []
            
                row_counter += 1
                if row_counter % 1000000 == 0:
                    print(f"{datetime.datetime.now().strftime('%H:%M:%S')} File {input_file}: Processed {row_counter//1000000} mln changesets")


        # Write any remaining rows after loop ends
        if data_chunk:
            print(f"{datetime.datetime.now().strftime('%H:%M:%S')} Writing final chunk of size {len(data_chunk)} to Parquet. {row_counter} changesets in total")
            df_chunk = pd.DataFrame(data_chunk)
            table = pa.Table.from_pandas(df_chunk)
            if writer is None:
                writer = pq.ParquetWriter(output_file, table.schema.remove_metadata())
            writer.write_table(table)

            if writer is not None:
                writer.close()

            
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert OSM changesets file (XML in bz2) to Parquet format with chunking.")
    parser.add_argument("-in", "--input", required=True, help="Path to the input .osm.bz2 file")
    parser.add_argument("-out", "--output", required=True, help="Path to the output Parquet file")
    parser.add_argument("-chunk", "--chunk_size", type=int, default=1000, help="Number of records per chunk (default: 1000)")

    args = parser.parse_args()

    convert_xml_to_parquet(args.input, args.output, args.chunk_size)
