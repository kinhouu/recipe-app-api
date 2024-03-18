"""
Test custom Django managment commands.
"""
# To mock behaviour of DB returning response
from unittest.mock import patch
# To catch one of the possible errors when trying to connect to DB, b4 DB is ready
from psycopg2 import OperationalError as Psycopg2Error
# To simulate calling a command we are testing
from django.core.management import call_command
# Another exception that may get thrown by DB, depending what stage the start up stage the DB is in
from django.db.utils import OperationalError
# Base test class for our unit tests
from django.test import SimpleTestCase

# Mocking the check command in wait_for_db.py, to simulate a response
@patch('core.management.commands.wait_for_db.Command.check')
class CommandTests(SimpleTestCase):
    """Test commnads."""

    def test_wait_for_db_ready(self, patched_check):
        """Test waiting for database if database is ready."""
        patched_check.return_value = True
        # Checking the command is set up correctly and can be called
        call_command('wait_for_db')
        # Ensures that correct parameters are used for command (on default DB)
        patched_check.assert_called_once_with(database=['default'])

    @patch('time.sleep')
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        """Test waiting for database when getting OperationalError."""
        # Simulating an exception instead of returning a value, using side_effect
        # side_effect - allows passing in of various attributes that will be handled differently depending on their type
        # If we pass in an exception, mocking library knows to raise that exception
        # If we pass in a boolean, mocking library returns the boolean value
        # Result: Raise 2 Psycopg2Errors, raise 3 Operational Errors and return True
        patched_check.side_effect = [Psycopg2Error] * 2 + \
            [OperationalError] * 3 + [True]
        
        call_command('wait_for_db')
        # Call check method 6 times (2 Pyscopg2Errors, 3 OperationalErrors, True)
        self.assertEqual(patched_check.call_count, 6)
        patched_check.assert_called_with(database=['default'])
