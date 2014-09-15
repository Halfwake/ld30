import fnmatch
import os
import zipfile

def valid_love_name(name):
    'Predicate for relevant love files.'
    return name.endswith('.lua') or name.endswith('.png') or name.endswith('.mp3') or name.endswith('.wav')

def relevant_file_names(): 
    'Filters file names.'
    return (name for name in os.listdir('.') if valid_love_name(name))

def archive(output_name, names):
    'Zips files into a new archive.'
    with zipfile.ZipFile(output_name, 'w') as zip_f_obj:
        for name in names:
            zip_f_obj.write(name)

if __name__ == '__main__':
    archive('test.love', relevant_file_names())
    
